class Invite < ActiveRecord::Base
  belongs_to :startup
  belongs_to :from, :class_name => 'User'
  belongs_to :to, :class_name => 'User'
  belongs_to :weekly_class
  before_save :generate_code
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  validates_presence_of :email, :if => :to_isnt_assigned?
  validates_presence_of :from_id
  validates_presence_of :invite_type
  validate :recipient_can_be_invited, :if => :new_record?

  after_create :notify_recipient

  attr_accessible :from_id, :to_id, :email, :msg, :startup, 
    :startup_id, :invite_type, :name, :weekly_class_id, :weekly_class

  @queue = :invites

  scope :accepted, where('accepted_at IS NOT NULL')
  scope :not_accepted, where(:accepted_at => nil)
  scope :to_mentors, lambda{ where(:invite_type => Invite::MENTOR) }
  scope :to_nreduce_mentors, lambda { where(:invite_type => Invite::NREDUCE_MENTOR) }
  scope :to_startups, lambda{ where(:invite_type => Invite::STARTUP) }
  scope :to_investors, lambda{ where(:invite_type => Invite::INVESTOR) }
  scope :ordered, order('created_at DESC')

  TEAM_MEMBER = 1
  MENTOR = 2
  NREDUCE_MENTOR = 3
  STARTUP = 4
  INVESTOR = 5
  # Make sure to add to perform method

  # Not adding nReduce types because it isn't allowed in user-selectable options
  def self.available_types
    {TEAM_MEMBER => 'Team Member', MENTOR => 'Mentor', INVESTOR => 'Investor'}
  end

  def self.types
    {TEAM_MEMBER => 'Team Member', MENTOR => 'Mentor', NREDUCE_MENTOR => 'nReduce Mentor', STARTUP => 'Startup', INVESTOR => 'Investor'}
  end

  def to_name 
    return self.name unless self.name.blank?
    return self.email unless self.email.blank?
    return self.to.name unless self.to.blank?
    return ''
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
    relationship_role = nil

    if self.invite_type == Invite::TEAM_MEMBER
      user.startup_id = self.startup_id if !self.startup_id.blank? or !user.startup_id.blank?
      user.set_account_type(:entrepreneur)
      # Bypass forcing user to setup account if they were invited from startup that is setup, also don't suggest startups
      user.setup_complete! if self.startup.account_setup?
    elsif self.invite_type == Invite::STARTUP
      user.set_account_type(:entrepreneur)
      relationship_role = :startup_startup
    elsif self.invite_type == Invite::MENTOR || self.invite_type == Invite::NREDUCE_MENTOR  # Add user as mentor to startup
      user.set_account_type(:mentor)
      user.roles << :nreduce_mentor if self.invite_type == Invite::NREDUCE_MENTOR
      relationship_role = :startup_mentor
    elsif self.invite_type == Invite::INVESTOR
      user.set_account_type(:investor)
      relationship_role = :startup_investor
    end

     # Add user to startup if invite came from startup
    if !self.startup.blank? and !relationship_role.blank?
      r = Relationship.start_between(user, self.startup, relationship_role, true)
      if r.blank?
        self.errors.add(:user_id, 'could not be added to startup')
      else
        self.errors.add(:user_id, 'could not be added to startup') unless r.approve!
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
    success = false
    if i.invite_type == MENTOR or i.invite_type == NREDUCE_MENTOR
      success = UserMailer.invite_mentor(i).deliver
    elsif i.invite_type == TEAM_MEMBER
      success = UserMailer.invite_team_member(i).deliver
    elsif i.invite_type == STARTUP
      success = UserMailer.invite_startup(i).deliver
    elsif i.invite_type == INVESTOR
      success = UserMailer.invite_investor(i).deliver
    end
    if success
      i.emailed_at = Time.now
      i.save
    end
  end
  
  protected

    # Checks if the "to" user is assigned
  def to_isnt_assigned?
    self.to_id.blank?
  end

  def recipient_can_be_invited
    user_with_email = User.where(:email => self.email).first
    self.to = user_with_email unless user_with_email.blank?
    # Check if user has startup - if so just create relationship
    if Invite.where(:email => self.email).not_accepted.count > 0
      self.errors.add(:email, 'has already been invited')
    elsif !user_with_email.blank? and !user_with_email.startup_id.blank?
      if user_with_email.startup_id == self.startup_id.to_i
        self.errors.add(:email, 'is already a team member on that startup')
      else
        self.errors.add(:email, 'is already a team member on another startup')
      end
    else
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
