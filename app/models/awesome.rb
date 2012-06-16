class Awesome < ActiveRecord::Base
  attr_accessible :awsm, :user_id, :awsm_type, :awsm_id
  belongs_to :awsm, :polymorphic => true

  after_create :update_awesome_count
  after_create :notify_users
  before_destroy :update_awesome_count

  validate :check_user_doesnt_own_object
  validates_presence_of :awsm_id
  validates_presence_of :awsm_type
  validates_presence_of :user_id

  def self.user_awesomed_object?(object, user_id)
    object.awesomes.where(:user_id => user_id).count
  end

  def unique_id
    "#{awsm_type}_#{awsm_id}_awesome"
  end

  def for_checkin?
    self.awsm_type == 'Checkin'
  end

  protected

  def check_user_doesnt_own_object
    if awsm.user_id == self.user_id
      self.errors.add :awsm, "can't awesome your own #{awsm.class.to_s.downcase}"
      false
    else
      true
    end
  end

  def update_awesome_count
    self.awsm.update_attribute('awesome_count', self.awsm.awesomes.count)
  end

  def notify_users
    Notification.create_for_new_awesome(self) if self.for_checkin?
  end
end
