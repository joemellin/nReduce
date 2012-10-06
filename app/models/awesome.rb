class Awesome < ActiveRecord::Base
  attr_accessible :awsm, :user_id, :awsm_type, :awsm_id
  belongs_to :awsm, :polymorphic => true
  belongs_to :user
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  after_create :update_awesome_count
  after_destroy :update_awesome_count
  after_create :notify_users

  validates_presence_of :awsm_id
  validates_presence_of :awsm_type
  validates_presence_of :user_id
  validate :check_user_doesnt_own_object

  def self.user_awesomed_object?(object, user_id)
    object.awesomes.where(:user_id => user_id).count
  end

  def self.unique_id_for_object(object)
    "#{object.class}_#{object.id}_awesome"
  end

  def unique_id
    "#{awsm_type}_#{awsm_id}_awesome"
  end

  def for_checkin?
    self.awsm_type == 'Checkin'
  end

  def for_comment?
    self.awsm_type == 'Comment'
  end

  def self.label_for_type(type)
    case type
    when 'Checkin' then 'Awesome'
    when 'Rating' then 'Value Add'
    when 'Comment' then 'Like'
    else 'Awesome'
    end
  end

  protected

  def check_user_doesnt_own_object
    if !awsm.blank? and (awsm.user_id == self.user_id) and !awsm.is_a?(Comment)
      self.errors.add :awsm, "can't awesome your own #{awsm.class.to_s.downcase}"
      false
    else
      true
    end
  end

  def update_awesome_count
    obj = self.awsm
    # Reset awesome cache for user
    Cache.delete(['awesome_ids', self.user])
    # Check if we need to update cached awesome count on object
    if obj && obj.respond_to?(:update_responders)
      obj.update_responders
    elsif obj && obj.respond_to?(:awesome_count)
      obj.awesome_count = obj.awesomes.count
      obj.save(:validate => false)
    end
    return true
  end

  def notify_users
    Notification.create_for_new_awesome(self) if self.for_checkin? || self.for_comment?
  end
end
