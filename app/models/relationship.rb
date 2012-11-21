class Relationship < ActiveRecord::Base
  # include the Connectable module in any classes you want some nice instance methods available for dealing with relationships
  belongs_to :entity, :polymorphic => true
  belongs_to :connected_with, :polymorphic => true
  has_many :notifications, :as => :attachable, :dependent => :destroy
  has_many :user_actions, :as => :attachable

  attr_accessible :context, :entity, :entity_id, :entity_type, :connected_with, :connected_with_id, 
    :connected_with_type, :status, :approved_at, :rejected_at, :silent, :message, :pending_at, :initiated, :introduced, :from_user_id

  serialize :seen_by, Array
  attr_accessor :silent
  attr_accessor :introduced
  attr_accessor :from_user_id

  before_create :set_pending_status_and_message_recipients
  after_create :notify_users, :unless => lambda{|r| r.silent == true }
  after_destroy :destroy_inverse_relationship_and_reset_cache

  # Statuses
  PENDING = 1
  APPROVED = 2
  REJECTED = 3
  SUGGESTED = 4
  PASSED = 5
  REMOVED = 6

  validates_presence_of :entity_id
  validates_presence_of :entity_type
  validates_presence_of :connected_with_id
  validates_presence_of :connected_with_type
  validate :entities_are_connectable, :if => lambda{|r| r.new_record? }

  scope :pending, where(:status => Relationship::PENDING)
  scope :approved, where(:status => Relationship::APPROVED)
  scope :rejected, where(:status => Relationship::REJECTED)
  scope :removed, where(:status => Relationship::REMOVED)
  scope :suggested, where(:status => Relationship::SUGGESTED)
  scope :passed, where(:status => Relationship::PASSED)
  scope :startup_to_user, where(:entity_type => 'Startup', :connected_with_type => 'User')
  scope :startup_to_startup, where(:entity_type => 'Startup', :connected_with_type => 'Startup')
  scope :not_suggested, where(:status => [Relationship::PENDING, Relationship::APPROVED, Relationship::REJECTED, Relationship::REMOVED])

  # Context of the relationship
  bitmask :context, :as => [:startup_startup, :startup_mentor, :startup_investor]

    # Classes that can be added to a relationship
    # When adding new ones make sure to also edit notifications and mailers
  def self.valid_classes
    %w(Startup User)
  end

   # Create a suggested connectino for an entity - it is created silently (no notifications)
  def self.suggest_connection(entity, connected_with, context = :startup_startup, message = nil)
    return nil if Relationship.between(entity, connected_with).present?
    r = Relationship.create(
      :entity => entity, 
      :connected_with => connected_with, 
      :status => Relationship::SUGGESTED, 
      :silent => true,
      :context => context, 
      :message => message, 
      :initiated => true
    )
  end

  # Start a relationship between two entities - same as calling create
  # @silent when set to true doesn't notify user of connection
  def self.start_between(entity, connected_with, context = :startup_startup, silent = false, dont_save = false, from_user_id = nil)
    r = Relationship.new(
      :entity => entity, 
      :connected_with => connected_with, 
      :status => Relationship::PENDING, 
      :silent => silent, 
      :context => context, 
      :initiated => true,
      :from_user_id => from_user_id
    )
    r.save unless dont_save
    r
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

  # Iterate through old relationships and figure out using dates which was the originator of the relationship
  def self.assign_initiated_relationships
    Relationship.not_suggested.each do |r|
      inv = r.inverse_relationship
      next if inv.blank?
      if r.created_at < inv.created_at
        r.initiated = true
        r.save
      else
        inv.initiated = true
        inv.save
      end
    end
  end

  # Returns the startups that these two entities are both connected to
  def self.startups_in_common(entity1, entity2)
    return [] if entity1.blank? || entity2.blank?
    entity_1_ids = Relationship.all_connection_ids_for(entity1)['Startup']
    entity_2_ids = Relationship.all_connection_ids_for(entity2)['Startup']
    return [] if entity_1_ids.blank? || entity_2_ids.blank?
    common = Relationship.all_connection_ids_for(entity1)['Startup'] & Relationship.all_connection_ids_for(entity2)['Startup']
    return Startup.where(:id => common) unless common.blank?
    []
  end

  # Approve the friendship and create a record in the opposite direction so friendship is easy to query
  def approve!
    # If this is a suggested relationship simply set to pending so the other person sees it
    if self.suggested?
      self.status = Relationship::PENDING
      self.pending_at = Time.now
      if self.save
        self.notify_users unless self.silent == true
        true
      else
        false
      end
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
            # If this was an introduction, notify the other team
            if self.introduced == true
              Notification.create_for_relationship_approved(inv)
            else
              Notification.create_for_relationship_approved(self)
            end
          end
          # Clear out notifications for this relationship
          self.notifications.each{|n| n.mark_as_read }
          # Reset relationship cache for both startups involved
          self.reset_cache_for_entities_involved
        end
      rescue ActiveRecord::RecordNotUnique
        # Relationship exists - check to see if it's in the right state
        # It could've been a previously suggested relationship that the entity wants to approve now (changed mind)
        r = Relationship.where(:entity_id => self.entity_id, :entity_type => self.entity_type, :connected_with_id => self.connected_with_id, :connected_with_type => self.connected_with_type).first
        r.approve! if !r.blank? && r.pending?
      end
      true
    end
  end

  # Reject the friendship (or pass on a suggestion), but don't delete records
  def reject_or_pass!
    Relationship.transaction do
      if self.pending?
        self.status = REJECTED
        self.rejected_at = Time.now
      elsif self.approved?
        self.status = REMOVED
        self.removed_at = Time.now
      elsif self.suggested?
        self.status = PASSED
        self.rejected_at = Time.now
      end
      inv = self.inverse_relationship
      inv = nil if inv.present? && (inv.rejected? || inv.passed? || inv.removed?)
      unless inv.blank?
        inv.status = self.status
        inv.removed_at = self.removed_at
        inv.rejected_at = self.rejected_at
        inv.save
      end
      self.save
       # Clear out notifications for this relationship
      self.notifications.each{|n| n.mark_as_read }
      # Reset relationship cache for both startups involved
      self.reset_cache_for_entities_involved
    end
    true
  end

  def seen_by?(user_id)
    self.seen_by.include?(user_id)
  end

  def mark_as_seen!(user_id)
    self.seen_by << user_id
    self.seen_by.uniq!
    self.save
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
    r.initiated = false
    r.silent = self.silent
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

  def removed?
    self.status == REMOVED
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
    Cache.delete(['n_a_s', "#{entity_type.downcase}_#{entity_id}"])
    Cache.delete(['n_a_s', "#{connected_with_type.downcase}_#{connected_with_id}"])
    if self.context == [:startup_startup]
      Cache.delete(['2d', "#{entity_type.downcase}_#{entity_id}"])
      Cache.delete(['2d', "#{connected_with_type.downcase}_#{connected_with_id}"])
      Cache.delete(['profile_c', "#{entity_type.downcase}_#{entity_id}"])
      Cache.delete(['profile_c', "#{connected_with_type.downcase}_#{connected_with_id}"])
    end
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
      self.errors.add(:entity, "is already suggested") if existing.suggested? || existing.passed?
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
      if r.rejected_at.blank?
        if r.removed_at.blank?
          end_at = Time.now
        else
          end_at = r.removed_at
        end
      else
        end_at = r.rejected_at
      end
      relationships[r.connected_with_type][r.connected_with_id] = [r.approved_at, end_at]
    end
    relationships
  end

  # Returns an array of all startup ids that are first and second degree connections of this startup
  def self.second_degree_connection_ids_for_startup(startup)
    ids = Cache.arr_get(['2d', startup])
    if ids.blank?
      ids = []
      startups = startup.connected_to('Startup')
      startups.each do |s|
        ids += s.connected_to_ids('Startup') 
        ids << s.id
      end
      Cache.arr_push(['2d', startup], ids)
    end
    ids
  end

  # Batch process that will calculate second degree connections and store it in Redis
  def self.calculate_second_degree_connections
    Startup.all.each do |s|
      Cache.delete(['2d', s])
      Relationship.second_degree_connection_ids_for_startup(s)
    end
  end

  protected

  def destroy_inverse_relationship_and_reset_cache
    self.inverse_relationship.destroy unless self.inverse_relationship.blank?
    self.reset_cache_for_entities_involved
  end

  def set_pending_status_and_message_recipients
    if self.status.blank?
      self.status = Relationship::PENDING
      self.pending_at = Time.now
    end
    if self.message.present? && self.from_user_id.present?
      user_ids = self.entity.is_a?(Startup) ? self.entity.team_member_ids : [self.entity.id]
      user_ids += self.connected_with.is_a?(Startup) ? self.connected_with.team_member_ids : [self.connected_with.id]
      c = Conversation.new(:participant_ids => user_ids, :messages => [Message.new(:from_id => from_user_id, :content => self.message)])
      c.save
    end
    true
  end

  def notify_users
    Notification.create_for_relationship_request(self) unless self.approved? # don't notify the inverse relationship when created
  end
end
