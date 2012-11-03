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

    # Loads only the startups that are considered active (checked in last two weeks)
  def active_startups
    Startup.active.where(:id => self.connected_to_ids('Startup'))
  end

  def inactive_startups
    Startup.inactive.where(:id => self.connected_to_ids('Startup'))
  end

  def num_active_startups
    Cache.get(['n_a_s', self], nil, true){
      Startup.active.where(:id => self.connected_to_ids('Startup')).count
    }.to_i    
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

  def second_degree_connection_ids
    return nil unless self.is_a?(Startup)
    Relationship.second_degree_connection_ids_for_startup(self) + [self.id]
  end

  def second_degree_connections
    Startup.find(self.second_degree_connection_ids)
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

  # Goes through active startups and suggests possible connections
  # Returns an array of suggested relationships

  def generate_suggested_connections(limit = 1000)
    # See if they are over limit of suggested connections
    relationships = self.suggested_relationships('Startup')
    return false if !relationships.blank? and (relationships.size >= limit)

    # Find all startups this person is connected to, has been suggested, and has rejected
    if self.is_a?(Startup)
      ignore_startup_ids = (self.received_relationships.not_suggested.where(:entity_type => 'Startup') + self.initiated_relationships.not_suggested.where(:connected_with_type => 'Startup')).map{|r| r.connected_with_id }
    elsif self.is_a?(User)
      ignore_startup_ids = (self.relationships.not_suggested.where(:entity_type => 'Startup') + self.connected_with_relationships.not_suggested.where(:connected_with_type => 'Startup')).map{|r| r.connected_with_id }
    end
    ignore_startup_ids << self.id if self.is_a?(Startup) # make sure this startup doesn't appear in suggested startups
    ignore_startup_ids << Startup.nreduce_id # hide nreduce from suggested startups
    ignore_startup_ids.uniq!

    # Find all startups that checked in last week
    if self.is_a?(Startup) || (self.is_a?(User) && self.entrepreneur?)
      startups = Startup.active.all.shuffle

      # Sort startups if this is a startup and they have less than the req'd # of active connections
      # This will suggest other startups that are also active but have few connections and few pending connections
      if self.is_a?(Startup) && self.num_active_startups < Startup::NUM_ACTIVE_REQUIRED
        num_pending = Relationship.where(:connected_with_id => startups.map{|s| s.id }, :connected_with_type => 'Startup').pending.group(:connected_with_id).count
        ranking = {}
        startups.each do |s|
          if num_pending[s.id].blank?
            ranking[s.id] = 0
          else
            # ranking is: (num active required - num active connections) / num pending connections
            ranking[s.id] = (Startup::NUM_ACTIVE_REQUIRED - s.num_active_startups) / num_pending[s.id]
          end
        end
        startups.sort{|a,b| ranking[a.id] <=> ranking[b.id] }.reverse!
      end 
    elsif self.mentor? || self.investor?
      startups = Startup.all_that_can_access_mentors_investors
    end

    return relationships if startups.blank?

    suggested = []

    startups.each do |s|
      break if suggested.size >= limit
      # Don't add if they're already connected or we're going to suggest them
      next if ignore_startup_ids.include?(s.id) || suggested.include?(s)
      # Suggest connection
      #relationships << Relationship.suggest_connection(self, s, :startup_startup)
      suggested << s
    end

    suggested
  end
end