class Relationship < ActiveRecord::Base
  # include the Connectable module in any classes you want some nice instance methods available for dealing with relationships
  belongs_to :entity, :polymorphic => true
  belongs_to :connected_with, :polymorphic => true
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessible :entity, :entity_id, :entity_type, :connected_with, :connected_with_id, :connected_with_type, :status, :approved_at, :rejected_at, :silent

  attr_accessor :silent

  after_create :notify_users, :unless => lambda{|r| !r.silent.blank? and r.silent? }

  # Statuses
  PENDING = 1
  APPROVED = 2
  REJECTED = 3

  validates_presence_of :entity_id
  validates_presence_of :entity_type
  validates_presence_of :connected_with_id
  validates_presence_of :connected_with_type
  validate :entities_are_connectable

  scope :pending, where(:status => Relationship::PENDING)
  scope :approved, where(:status => Relationship::APPROVED)
  scope :rejected, where(:status => Relationship::REJECTED)

    # Classes that can be added to a relationship
    # When adding new ones make sure to also edit notifications and mailers
  def self.valid_classes
    ['Startup', 'User']
  end

    # Start a relationship from form params
  def self.start_from_params(params)
    params[:entity_type].titleize
    params[:connected_with_type].titleize
    entity = params[:entity_type].constantize.find(params[:entity_id]) if Relationship.valid_classes.include?(params[:entity_type])
    connected_with = params[:connected_with_type].constantize.find(params[:connected_with_id]) if Relationship.valid_classes.include?(params[:connected_with_type])
    if entity and connected_with
      Relationship.start_between(entity, connected_with)
    else
      return "Could not start a relationship."
    end
  end

  # Start a relationship between two entities
  def self.start_between(entity, connected_with, silent = false)
    return nil if entity == connected_with
    # Check if a relationship already exists
    existing = Relationship.between(entity, connected_with)
    return existing unless existing.blank?
    # Create new pending relationship
    Relationship.create(:entity => entity, :connected_with => connected_with, :status => Relationship::PENDING, :silent => silent)
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

    # Returns boolean whether these two entities are connectable enabled, and not the same object
    # Checks whether it's two startups, or a startup and a mentor
  def self.can_connect?(entity1, entity2)
    Relationship.new(:entity => entity1, :connected_with => entity2).valid?
  end

    # Returns hash with all classes/ids this entity is connected to {'Startup' => [id, id], 'User' => [id, id]}
  def self.all_connection_ids_for(entity)
    # Cache doesn't work for hash
    Cache.get(['connections', entity]){
      ret = {}
      entity.relationships.approved.each{|r| ret[r.connected_with_type] ||= []; ret[r.connected_with_type] << r.connected_with_id }
      ret
    }
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
    Relationship.where(:entity_id => connected_with_id, :entity_type => connected_with_type, :connected_with_id => entity_id, :connected_with_type => entity_type).first
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

  def entities_are_connectable
    self.errors.add(:entity_type, "can't be connected") if !entity.connectable? or !Relationship.valid_classes.include?(entity_type)
    self.errors.add(:connected_with_type, "can't be connected") if !connected_with.connectable? or !Relationship.valid_classes.include?(connected_with_type)
    self.errors.add(:entity_type, "can't be connected to itself") if entity == connected_with
    # Now check if these two types can be connected
    if entity.is_a?(Startup) and connected_with.is_a?(Startup)
      return true
    elsif entity.is_a?(Startup) and (connected_with.is_a?(User) and connected_with.mentor?)
      return true
    elsif connected_with.is_a?(Startup) and (entity.is_a?(User) and entity.mentor?)
      return true
    else
      self.errors.add(:entity_type, "can't be connected to a #{connected_with_type.downcase}")
    end
  end

  def reset_cache_for_entities_involved
    Cache.delete(['connections', "#{entity_type.downcase}_#{entity_id}"])
    Cache.delete(['connections', "#{connected_with_type.downcase}_#{connected_with_id}"])
  end

  def notify_users
    Notification.create_for_relationship_request(self) unless self.approved? # don't notify the inverse relationship when created
  end
end
