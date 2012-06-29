class Relationship < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true
  belongs_to :connected_with, :polymorphic => true
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessible :entity, :connected_with, :status, :approved_at, :rejected_at

  after_create :notify_users

  # Statuses
  PENDING = 1
  APPROVED = 2
  REJECTED = 3

  validates_presence_of :entity_id
  validates_presence_of :connected_with_id

  scope :pending, where(:status => Relationship::PENDING)
  scope :approved, where(:status => Relationship::APPROVED)
  scope :rejected, where(:status => Relationship::REJECTED)

  # Start a relationship between two entities
  def self.start_between(entity, connected_with)
    return nil if entity == connect_with
    # Check if a relationship already exists
    existing = Relationship.between(entity, connected_with)
    return existing unless existing.blank?
    # Create new pending relationship
    Relationship.create(:entity => entity, :connected_with => connected_with, :status => Relationship::PENDING)
  end

    # Finds relationship between two entities
  def self.between(entity1, entity2)
    Relationship.where(:entity_id => entity1.id, :entity_type => entity1.class, :connected_with_id => entity2.id, :connected_with_type => entity2.class).order('created_at DESC').first
  end

    # Returns all entities of a specific class that this entity is connected to (approved status)
    # @class_name_string should be string like Startup
  def self.all_connections_for(entity, class_name_string)
    ids = Relationship.all_connection_ids_for(entity)
    if !ids.blank? and ids[class_name_string]
      class_name_string.constantize.where(:id => ids[class_name_string])
    else
      []
    end
  end

    # Returns hash with all classes/ids this entity is connected to {'Startup' => [id, id], 'User' => [id, id]}
  def self.all_connection_ids_for(entity)
    # Cache doesn't work for hash
    #Cache.get(['connections', entity]){
      ret = {}
      entity.relationships.approved.each{|r| ret[r.connected_with_type] ||= []; ret[r.connected_with_type] << r.connected_with_id }
      ret
    #}
  end

    # Returns all startups that this startup has initiated, but are still pending
  def self.all_pending_relationships_for(entity)
    Relationship.where(:connected_with_id => entity.id, :connected_with_type => entity.class).pending
  end

    # Returns all pending relationships that other startups have initiated with this startup
  def self.all_requested_relationships_for(entity)
    entity.relationships.pending
  end

  # Approve the friendship and create a record in the opposite direction so friendship is easy to query
  def approve!
    begin
      Relationship.transaction do
        self.update_attributes(:status => APPROVED, :approved_at => Time.now) unless self.approved?
        inv = self.inverse_relationship
        if !inv.blank?
          inv.update_attributes(:status => APPROVED, :approved_at => Time.now) unless inv.approved?
        else
          Relationship.create(:entity_id => connected_with_id, :entity_type => connected_with_type, :connected_with_id => entity_id, :connected_with_type => entity_type, :status => APPROVED, :approved_at => Time.now)
          Notification.create_for_relationship_approved(self)
        end
        # Reset relationship cache for both startups involved
        self.reset_cache_for_entities_involved
      end
    rescue ActiveRecord::RecordNotUnique
      # Already approved don't need to do anything
    end
    true
  end

  # Reject the friendship, but don't delete records
  def reject!
    begin
      Relationship.transaction do
        self.update_attributes(:status => REJECTED, :rejected_at => Time.now) unless self.rejected?
        inv = self.inverse_relationship
        inv.update_attributes(:status => REJECTED, :rejected_at => Time.now) unless inv.blank? or inv.rejected?
        self.reset_cache_for_entities_involved
      end
    rescue ActiveRecord::RecordNotUnique
      # Already rejected don't need to do anything
    end
    true
  end

  def inverse_relationship
    Relationship.where(:startup_id => connected_with_id, :connected_with_id => startup_id).first
  end

  def pending?
    self.status == PENDING
  end

  def approved?
    self.status == APPROVED
  end

  def rejected?
    self.status == REJECTED
  end

  protected

  def reset_cache_for_startups_involved
    Cache.delete(['connections', "#{entity.type.downcase}_#{entity_id}"])
    Cache.delete(['connections', "#{connected_with_type.downcase}_#{connected_with_id}"])
  end

  def notify_users
    Notification.create_for_relationship_request(self) unless self.approved? # don't notify the inverse relationship when created
  end
end
