class Relationship < ActiveRecord::Base
  # include the Connectable module in any classes you want some nice instance methods available for dealing with relationships
  belongs_to :entity, :polymorphic => true
  belongs_to :connected_with, :polymorphic => true
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessible :context, :entity, :entity_id, :entity_type, :connected_with, :connected_with_id, :connected_with_type, :status, :approved_at, :rejected_at, :silent, :message, :pending_at

  attr_accessor :silent

  before_create :set_pending_status
  after_create :notify_users, :unless => lambda{|r| r.silent == true }
  after_destroy :destroy_inverse_relationship_and_reset_cache

  # Statuses
  PENDING = 1
  APPROVED = 2
  REJECTED = 3
  SUGGESTED = 4
  PASSED = 5

  validates_presence_of :entity_id
  validates_presence_of :entity_type
  validates_presence_of :connected_with_id
  validates_presence_of :connected_with_type
  validate :entities_are_connectable, :if => lambda{|r| r.new_record? }

  scope :pending, where(:status => Relationship::PENDING)
  scope :approved, where(:status => Relationship::APPROVED)
  scope :rejected, where(:status => Relationship::REJECTED)
  scope :suggested, where(:status => Relationship::SUGGESTED)
  scope :passed, where(:status => Relationship::PASSED)
  scope :startup_to_user, where(:entity_type => 'Startup', :connected_with_type => 'User')
  scope :startup_to_startup, where(:entity_type => 'Startup', :connected_with_type => 'Startup')

  # Context of the relationship
  bitmask :context, :as => [:startup_startup, :startup_mentor, :startup_investor]

    # Classes that can be added to a relationship
    # When adding new ones make sure to also edit notifications and mailers
  def self.valid_classes
    %w(Startup User)
  end

   # Create a suggested connectino for an entity - it is created silently (no notifications)
  def self.suggest_connection(entity, connected_with, context = :startup_startup, message = nil)
    Relationship.create(:entity => entity, :connected_with => connected_with, :status => Relationship::SUGGESTED, :silent => true, :context => context, :message => message)
  end

  # Start a relationship between two entities - same as calling create
  # @silent when set to true doesn't notify user of connection
  def self.start_between(entity, connected_with, context = :startup_startup, silent = false)
    Relationship.create(:entity => entity, :connected_with => connected_with, :status => Relationship::PENDING, :silent => silent, :context => context)
  end

    # Finds relationship between two entities
  def self.between(entity1, entity2)
    Relationship.where(:entity_id => entity1.id, :entity_type => entity1.class, :connected_with_id => entity2.id, :connected_with_type => entity2.class).order('created_at DESC').first
  end

  def self.suggested_connections_for(entity, class_name_string)
    rel = Relationship.where(:entity_id => entity.id, :entity_type => entity.class).suggested
    rel = rel.where(:connected_with_type => class_name_string) unless class_name_string.blank?
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

  def self.all_pending_or_approved_relationships_for(entity)
    Relationship.all_requested_relationships_for(entity) + entity.relationships.approved.all
  end

    # Returns all pending relationships that other startups have initiated with this startup
  def self.all_requested_relationships_for(entity)
    entity.relationships.pending
  end

  # Approve the friendship and create a record in the opposite direction so friendship is easy to query
  def approve!
    # If this is a suggested relationship simply set to pending so the other person sees it
    if self.suggested?
      self.status = Relationship::PENDING
      self.pending_at = Time.now
      self.save
    else
      begin
        Relationship.transaction do
          self.update_attributes(:status => APPROVED, :approved_at => Time.now) unless self.approved?
          inv = self.inverse_relationship
          if !inv.blank?
            inv.update_attributes(:status => APPROVED, :approved_at => Time.now) unless inv.approved?
          else
            inv = self.new_inverse_relationship
            inv.save
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
  end

  # Reject the friendship (or pass on a suggestion), but don't delete records
  def reject_or_pass!
    begin
      Relationship.transaction do
        new_status = self.suggested? ? PASSED : REJECTED
        self.update_attributes(:status => new_status, :rejected_at => Time.now) unless self.rejected?
        inv = self.inverse_relationship
        inv.update_attributes(:status => new_status, :rejected_at => Time.now) unless inv.blank? or (inv.rejected? or inv.passed?)
        self.reset_cache_for_entities_involved
      end
    rescue ActiveRecord::RecordNotUnique
      # Already rejected don't need to do anything
    end
    true
  end

  def inverse_relationship
    Relationship.where(:entity_id => self.connected_with_id, :entity_type => self.connected_with_type, :connected_with_id => self.entity_id, :connected_with_type => self.entity_type).first
  end

  # Clones current object and populates a new object with same attribtues, but entity and connected_with are swapped
  def new_inverse_relationship
    r = self.dup
    r.id = nil
    # Switch entity and connected with
    r.entity_id = self.connected_with_id
    r.entity_type = self.connected_with_type
    r.connected_with_id = self.entity_id
    r.connected_with_type = self.entity_type
    r
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

  def suggested?
    self.status == SUGGESTED
  end

  def passed?
    self.status == PASSED
  end

    # Returns boolean true if entity is involved in this relationship - checks without db query
  def is_involved?(entity)
    return true if entity_type == entity.class.to_s and entity_id == entity.id
    return true if connected_with_type == entity.class.to_s and connected_with_id == entity.id
    false
  end

  def reset_cache_for_entities_involved
    Cache.delete(['connections', "#{entity_type.downcase}_#{entity_id}"])
    Cache.delete(['connections', "#{connected_with_type.downcase}_#{connected_with_id}"])
    # Not caching suggested connections yet
    #Cache.delete(['sugg_connections', "#{entity_type.downcase}_#{entity_id}"])
    #Cache.delete(['sugg_connections', "#{connected_with_type.downcase}_#{connected_with_id}"])
  end

  def entities_are_connectable
    self.errors.add(:entity, "can't be connected") if !entity.connectable? or !Relationship.valid_classes.include?(entity_type)
    self.errors.add(:connected_with, "can't be connected") if !connected_with.connectable? or !Relationship.valid_classes.include?(connected_with_type)
    self.errors.add(:entity, "can't be connected to itself") if entity == connected_with
    
    # Check if there is already a connection
 
    existing = Relationship.between(entity, connected_with)
    unless existing.blank?
      self.errors.add(:connected_with, "hasn't approved your request yet") if existing.pending?
      self.errors.add(:entity, "is already connected to #{connected_with.name}") if existing.approved?
      self.errors.add(:connected_with, "has ignored your request") if existing.rejected?
    end

    # Now check if these two types can be connected
    if entity.is_a?(Startup) and connected_with.is_a?(Startup)
      self.context = :startup_startup
      return true
    elsif entity.is_a?(Startup) and (connected_with.is_a?(User) and connected_with.mentor?)
      self.context = :startup_mentor
      return true
    elsif connected_with.is_a?(Startup) and (entity.is_a?(User) and entity.mentor?)
      self.context = :startup_mentor
      return true
    elsif connected_with.is_a?(Startup) and (entity.is_a?(User) and entity.investor?)
      self.context = :startup_investor
      return true
    else
      self.errors.add(:entity, "can't be connected to a #{connected_with_type.downcase}")
    end
  end

  # Gets connection details and returns a hash organized by class and then id, with an array of dates they were connected from and to
  # ex: {'Startup' => {1 => [Thu, 19 Jul 2012 14:58:46 PDT -07:00, 2012-07-20 20:59:56 -0700]}}
  # Can limit to only connections with a certain type of object (ex: Startup)
  def self.history_for_entity(entity, connected_with_type = nil)
    relationships = {}
    rel = Relationship.where(:entity_type => entity.class, :entity_id => entity.id)
    # only get approved or rejected relationships
    rel = rel.where(['status = ? OR status = ?', Relationship::APPROVED, Relationship::REJECTED])
    # limit by connected entity type if provided
    rel = rel.where(:connected_with_type => connected_with_type) unless connected_with_type.blank?
    rel.each do |r|
      next if r.approved_at.blank? # ignore relationships that were rejected without ever being approved
      relationships[r.connected_with_type] ||= {}
      relationships[r.connected_with_type][r.connected_with_id] = [r.approved_at, r.rejected_at.blank? ? Time.now : r.rejected_at]
    end
    relationships
  end

  protected

  def destroy_inverse_relationship_and_reset_cache
    self.inverse_relationship.destroy unless self.inverse_relationship.blank?
    self.reset_cache_for_entities_involved
  end

  def set_pending_status
    if self.status.blank?
      self.status = Relationship::PENDING
      self.pending_at = Time.now
    end
  end

  def notify_users
    Notification.create_for_relationship_request(self) unless self.approved? # don't notify the inverse relationship when created
  end
end
