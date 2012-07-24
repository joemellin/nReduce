module Connectable
	def self.included(base)
		# Adding relationships here so it doesn't complain that active_record isn't avail
		base.class_eval do
			has_many :relationships, :as => :entity
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

  def suggested_relationships
    Relationship.suggested_connections_for(self)
  end

  # Connections that they were suggested but passed on
  def passed_relationships(entity_class_string)
    Relationship.where(:entity_id => self.id, :entity_class => self.class, :connected_with_type => entity_class_string).passed
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
end