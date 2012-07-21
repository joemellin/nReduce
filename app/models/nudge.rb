class Nudge < ActiveRecord::Base
  belongs_to :from, :class_name => 'User'
  belongs_to :startup # Nudge is being sent to this startup
  belongs_to :invite  # or to this invite
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessible :from_id, :startup_id, :invite_id

  validates_presence_of :from_id
  validate :startup_or_invite_present

  after_create :notify_users

  @queue = :invite_nudge

  def to_name
    return self.startup.name unless self.startup_id.blank?
    return self.invite.to_name unless self.invite_id.blank?
    nil
  end

  # Send mail to nudge user who hasn't claimed invite
  def self.perform(id)
    nudge = Nudge.find(id)
    UserMailer.nudge_for_invite(nudge).deliver if !nudge.invite.blank? and nudge.invite.active?
  end

  protected

  def notify_users
    if self.invite_id.blank?
      Notification.create_for_new_nudge(self)
    else # not a user so can't create notification
      Resque.enqueue(Nudge, self.id)
    end
  end

  def startup_or_invite_present
    self.errors.add(:startup_id, "can't be blank") if self.startup_id.blank? and self.invite_id.blank?
  end
end
