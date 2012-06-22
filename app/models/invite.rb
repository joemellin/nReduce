class Invite < ActiveRecord::Base
  belongs_to :startup
  belongs_to :from, :class_name => 'User'
  belongs_to :to, :class_name => 'User'
  before_save :generate_code

  validates_presence_of :email
  validates_presence_of :from_id

  attr_accessible :from_id, :to_id, :email, :msg, :startup_id

  @queue = :invites

  scope :not_accepted, where(:accepted_at => nil)

  def self.types
    {'team member' => 1, 'mentor' => 2}
  end

  def self.invite_team_member(prms)
    i = Invite.new(prms)
    if Invite.where(:email => prms[:email]).count > 0
      i.errors.add(:email, 'has already been invited')
    else
      user_with_email = User.where(:email => prms[:email]).first
      i.invite_type = Invite.types['team member']
      i.to = user_with_email unless user_with_email.blank?
      i.expires_at = Time.now + 30.days
      Resque.enqueue(Invite, i.id.to_s) if i.save # queue to send email
    end
    i
  end
  
  def active? # not expired, and not accepted yet
    !self.expired? and self.accepted_at.nil?
  end
  
  def expired?
    return true if self.expires_at.blank?
    Time.now > self.expires_at
  end
  
    # called when an invite is accepted
  def accepted_by(user)
    return false unless self.active?
    # assign user to startup unless they are already part of a startup
    user.startup_id = self.startup_id if !self.startup_id.blank? or !user.startup_id.blank?
    if user.save
      self.to = user
      self.accepted_at = Time.now
      self.save
    else
      false
    end
  end
  
  def invalidate!
    self.expires_on = Time.now - 1.minute
    self.save
  end

    # Updates all people on shared trip of updates
  def self.perform(invite_id)
    i = Invite.find(invite_id)
    UserMailer.invite_team_member(i).deliver
  end
  
  protected

  def generate_code
    self.code = NreduceUtil.friendly_token if self.code.blank?
  end
end
