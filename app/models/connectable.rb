module Connectable
	def self.included(base)
		# Adding relationships here so it doesn't complain that active_record isn't avail
		base.class_eval do
			has_many :relationships, :as => :entity
      attr_accessor :cached_relationship
		end
	end

    # Returns a string that can be used to represent object
  def obj_str
    "#{self.class}_#{self.id}"
  end

    # Entities this one is connected to, of a specific class
    # uses cache
  def connected_to(class_name_string = 'Startup')
    Relationship.all_connections_for(self, class_name_string)
  end

    # Entity ids for a specific class that this entity is connected to
  def connected_to_ids(class_name_string = 'Startup')
    ids = Relationship.all_connection_ids_for(self)
    return ids[class_name_string] if !ids.blank? and !ids[class_name_string].blank?
    return []
  end

	  # Relationships this entity as requested with others
    # not cached
  def requested_relationships
    Relationship.all_requested_relationships_for(self)
  end

    # relationships that other entities have requested with this entity
    # not cached
  def pending_relationships
    Relationship.all_pending_relationships_for(self)
  end

  def pending_or_approved_relationships
    Relationship.all_pending_or_approved_relationships_for(self)
  end

  def suggested_relationships(class_name_string = nil)
    Relationship.suggested_connections_for(self, class_name_string)
  end

  # Connections that they were suggested but passed on
  def passed_relationships(entity_class_string)
    Relationship.where(:entity_id => self.id, :entity_type => self.class, :connected_with_type => entity_class_string).passed
  end

    # Returns true if this entity is connected in an approved relationship
    # uses cache
  def connected_to?(entity)
    self.connected_to_id?(entity.id, entity.class.to_s)
  end

  	# If you don't have the object, you can pass the id and class string to see if these two are connected
  def connected_to_id?(entity_id, entity_class_string)
    ids = Relationship.all_connection_ids_for(self)
    return ids[entity_class_string].include?(entity_id) if !ids.blank? and !ids[entity_class_string].blank?
    return false
  end

    # Returns true if these two starts are connected, or if the provided startup requested to be connected to this startup
    # not cached
  def connected_or_pending_to?(entity)
    # check reverse direction because we need to see if pending request is coming from other startup
    r = Relationship.between(entity, self)
    return true if r and (r.pending? or r.approved?)
    false
  end

  def start_relationship_with(connect_with)
  	Relationship.start_between(self, connect_with)
  end

  def relationship_with(connected_with)
  	Relationship.between(self, connected_with)
  end

  def connectable?
  	true
  end

  def delete_suggested_startups
    self.suggested_relationships('Startup').each{|r| r.reject_or_pass! }
  end

  def suggested_startups(limit = 10)
    relationships = self.suggested_relationships('Startup')
    startup_ids = relationships.map{|r| r.connected_with_id }
    r_by_id = Hash.by_key(relationships, :connected_with_id)
    Startup.find(startup_ids.first(limit)).map{|s| s.cached_relationship = r_by_id[s.id] unless r_by_id[s.id].blank?; s }
  end

   def generate_suggested_connections(limit = 10)
    # See if they are over limit of suggested connections
    suggested = self.suggested_startups(limit + 5)
    return false if !suggested.blank? and (suggested.size >= limit)

    # Find all startups this person is connected to, has been suggested, and has rejected
    ignore_startup_ids = (self.received_relationships.where(:entity_type => 'Startup') + self.initiated_relationships.where(:connected_with_type => 'Startup')).map{|r| r.connected_with_id }
    ignore_startup_ids << self.id if self.is_a?(Startup) # make sure this startup doesn't appear in suggested startups
    ignore_startup_ids << Startup.nreduce_id # hide nreduce from suggested startups
    ignore_startup_ids.uniq!

    # Find all startups that checked in last week
    end_after = Checkin.prev_after_checkin
    start_after = end_after - 24.hours
    checkins = Checkin.completed.where(['completed_at >= ? AND completed_at <= ?', start_after, end_after]).includes(:startup).all

    return suggested if checkins.blank?

    1.upto(checkins.size) do
      break if suggested.size >= limit
      # Randomly get a startup from one that checked in last week
      s = checkins.sample.startup
      # Make sure startup still exists
      next if s.blank?
      # Don't add if they're already connected or we're going to suggest them
      next if ignore_startup_ids.include?(s.id) || suggested.include?(s)
      # Suggest connection
      Relationship.suggest_connection(self, s, :startup_startup)
      suggested << s
    end

    suggested
  end

    # Generate suggestion connections that this startup might like to connect to - based on similar industries and company goal
  def generate_suggested_connections_old(limit = 4)
    startups = []
    # See if they are over limit of suggested connections
    suggested = self.suggested_startups(limit + 5)
    return false if !suggested.blank? and (suggested.size >= limit)
    num_suggested = suggested.size

    # Find all startups this person is connected to, has been suggested, and has rejected
    ignore_startup_ids = (self.received_relationships.where(:entity_type => 'Startup') + self.initiated_relationships.where(:connected_with_type => 'Startup')).map{|r| r.connected_with_id }
    ignore_startup_ids << self.id if self.is_a?(Startup) # make sure this startup doesn't appear in suggested startups
    ignore_startup_ids << Startup.nreduce_id # hide nreduce from suggested startups
    ignore_startup_ids.uniq!

     # Create lambda to add startups that will create a suggested relationship when passed an array of startups
    suggest_startups = Proc.new {|startups, message|
      startups.each do |s|
        break if num_suggested >= limit
        Relationship.suggest_connection(self, s, :startup_startup, message)
        num_suggested += 1
      end
    }

    industry_ids = self.industries.map{|t| t.id }

    # If this object is an investor then just pull companies that say they are looking for investment
    if self.is_a?(User) and self.investor?
      search = Startup.search do
        with :investable, true
        with(:num_checkins).greater_than(1) # (greater_than is greater than or equal to)
        without :id, ignore_startup_ids
        order_by :rating, :desc
        order_by :num_checkins, :desc
        paginate :per_page => limit
      end
      unless search.results.blank?
        startups += search.results
        ignore_startup_ids += startups.map{|s| s.id }
        suggest_startups.call(startups, nil)
      end

    # If this is a startup do some searches for matching companies
    elsif self.is_a?(Startup)

      # Matching on all industries & company goal
      unless industry_ids.blank?
        search = Startup.search do
          all_of do
            with :industry_tag_ids, industry_ids
          end
          with(:num_checkins).greater_than(1) # (greater_than is greater than or equal to)
          with(:num_pending_relationships).less_than(10)
          with :company_goal, self.company_goal
          without :id, ignore_startup_ids
          order_by :rating, :desc
          order_by :num_checkins, :desc
          paginate :per_page => limit
        end
        unless search.results.blank?
          startups += search.results
          ignore_startup_ids += startups.map{|s| s.id }
          suggest_startups.call(startups, 'same industry & company goal')
        end
      end
      

      # Matching on all industries
      if startups.size < limit && !industry_ids.blank?
        search = Startup.search do
          all_of do
            with :industry_tag_ids, industry_ids
          end
          with(:num_checkins).greater_than(1)
          with(:num_pending_relationships).less_than(10)
          without :id, ignore_startup_ids
          order_by :rating, :desc
          order_by :num_checkins, :desc
          paginate :per_page => limit
        end
        unless search.results.blank?
          startups += search.results
          ignore_startup_ids += startups.map{|s| s.id }
          suggest_startups.call(startups, 'same industry')
        end
      end

      # Matching on any industry
      if startups.size < limit && !industry_ids.blank?
        search = Startup.search do
          any_of do
            with :industry_tag_ids, industry_ids
          end
          with(:num_checkins).greater_than(1)
          with(:num_pending_relationships).less_than(10)
          without :id, ignore_startup_ids
          order_by :rating, :desc
          order_by :num_checkins, :desc
          paginate :per_page => limit
        end
        unless search.results.blank?
          startups += search.results
          ignore_startup_ids += startups.map{|s| s.id }
          suggest_startups.call(startups, 'same industry')
        end
      end

      # Matching on company stage
      if startups.size < limit and !self.stage.blank?
        search = Startup.search do
          with :stage, self.stage
          with(:num_checkins).greater_than(1)
          with(:num_pending_relationships).less_than(10)
          without :id, ignore_startup_ids
          order_by :rating, :desc
          order_by :num_checkins, :desc
          paginate :per_page => 2
        end
        unless search.results.blank?
          startups += search.results
          ignore_startup_ids += startups.map{|s| s.id }
          suggest_startups.call(startups, "same company stage")
        end
      end

      # Matching on company goal
      if startups.size < limit and !self.company_goal.blank?
        search = Startup.search do
          with :company_goal, self.company_goal
          with(:num_checkins).greater_than(1)
          with(:num_pending_relationships).less_than(10)
          without :id, ignore_startup_ids
          order_by :rating, :desc
          order_by :num_checkins, :desc
          paginate :per_page => 2
        end
        unless search.results.blank?
          startups += search.results
          ignore_startup_ids += startups.map{|s| s.id }
          suggest_startups.call(startups, "same company goal")
        end
      end
    end

    startups
  end
end