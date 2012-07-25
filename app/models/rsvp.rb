class Rsvp < ActiveRecord::Base
  belongs_to :demo_day
  belongs_to :user
  belongs_to :startup

  attr_accessible :demo_day_id, :user_id, :startup_id, :message, :email, :accredited

  validates_presence_of :demo_day_id
  validate :user_or_email_present

  protected

  def user_or_email_present
    if user_id.blank? and email.blank?
      self.errors.add(:user_id, "can't be blank")
      false
    else
      true
    end
  end
end
