class Nudge < ActiveRecord::Base
  belongs_to :from, :class_name => 'User'
  belongs_to :startup

  attr_accessible :from_id, :startup_id

  validates_presence_of :from_id
  validates_presence_of :startup_id

  after_create :notify_users

  protected

  def notify_users
    Notification.create_for_new_nudge(self)
  end
end
