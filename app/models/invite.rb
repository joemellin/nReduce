class Invite < ActiveRecord::Base
  belongs_to :startup
  belongs_to :from, :class_name => 'User'
  belongs_to :to, :class_name => 'User'
  before_save :generate_code
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  validates_presence_of :email
  validates_presence_of :from_id
  validates_presence_of :invite_type
  validate :recipient_can_be_invited, :if => :new_record?

  after_create :notify_recipient

  attr_accessible :from_id, :to_id, :email, :msg, :startup, :startup_id, :invite_type

  @queue = :invites

  scope :not_accepted, where(:accepted_at => nil)

  TEAM_MEMBER = 1
  MENTOR = 2

  def self.types
    {TEAM_MEMBER => 'team member', MENTOR => 'mentor'}
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
    if self.invite_type == TEAM_MEMBER  
      user.startup_id = self.startup_id if !self.startup_id.blank? or !user.startup_id.blank?
    # Add user as mentor to startup
    elsif self.invite_type == MENTOR
      user.mentor = true
      r = Relationship.start_between(user, self.startup, true)
      if r.blank?
        self.errors.add(:user_id, 'could not be added to team')
      else
        self.errors.add(:user_id, 'could not be added to team') unless r.approve!
      end
    end
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
    if i.invite_type == MENTOR
      UserMailer.invite_mentor(i).deliver
    elsif i.invite_type == TEAM_MEMBER
      UserMailer.invite_team_member(i).deliver
    end
  end
  
  protected

  def recipient_can_be_invited
    user_with_email = User.where(:email => self.email).first
    if Invite.where(:email => self.email).not_accepted.count > 0
      self.errors.add(:email, 'has already been invited')
    elsif !user_with_email.blank? and !user_with_email.startup_id.blank?
      if user_with_email.startup_id == self.startup_id.to_i
        self.errors.add(:email, 'is already a team member on that startup')
      else
        self.errors.add(:email, 'is already a team member on another startup')
      end
    else
      self.to = user_with_email unless user_with_email.blank?
      self.expires_at = Time.now + 30.days
    end
  end 

  def generate_code
    self.code = NreduceUtil.friendly_token(20) if self.code.blank?
  end

  def notify_recipient
    Resque.enqueue(Invite, self.id.to_s) # queue to send email
  end
end
