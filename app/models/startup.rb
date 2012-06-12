class Startup < ActiveRecord::Base
  has_many :team_members, :class_name => 'User'
  has_many :checkins
  belongs_to :main_contact, :class_name => 'User'
  belongs_to :meeting
  has_many :relationships

  attr_accessible :name, :team_size, :website_url, :main_contact_id, :phone, :growth_model, :stage, :company_goal, :meeting_id, :one_liner, :active, :launched_at, :industry_list, :technology_list, :ideology_list, :industry

  serialize :team_members

  validates_presence_of :name
  validate :check_video_urls_are_valid

  acts_as_taggable_on :industries, :technologies, :ideologies

  # Use S3 for production
  # http://blog.tristanmedia.com/2009/09/using-amazons-cloudfront-with-rails-and-paperclip/
  if Rails.env.production?
    has_attached_file :logo, Settings.paperclip_config.to_hash.merge!({
      :storage => 's3',
      :s3_credentials => Settings.aws.s3.to_hash,
      :s3_headers => { 'Expires' => 1.year.from_now.httpdate },
      :default_url => "http://www.nreduce.com/assets/avatar_:style.png",
      :s3_protocol => 'https'
    })
  else
    has_attached_file :logo, Settings.paperclip_config.to_hash
  end

  scope :is_public, where(:public => true)
  scope :launched, where('launched_at IS NOT NULL')
  scope :with_intro_video, where('intro_video_url IS NOT NULL')

    # Startups this one is connected to (approved status)
  def connected_to
    Relationship.all_connections_for(self)
  end

    # Relationships this startup has requested with others
  def requested_relationships
    Relationship.all_requested_relationships_for(self)
  end

    # relationships that other startups have requested with this startup
  def pending_relationships
    Relationship.all_pending_relationships_for(self)
  end

    # Returns true if these two startups are connected in an approved relationship
  def connected_to?(startup)
    r = Relationship.between(self, startup)
    r and r.approved?
  end

    # Returns true if these two starts are connected, or if the provided startup requested to be connected to this startup
  def connected_or_pending_to?(startup)
    # check reverse direction because we need to see if pending request is coming from other startup
    r = Relationship.between(startup, self)
    return true if r and (r.pending? or r.approved?)
    false
  end

   # Returns the checkin for this week (or if Sun/Mon, it checks for last week's checkin)
  def current_checkin
    checkins.current.first
  end

  def onboarding_step_increment!
    self.update_attribute('onboarding_step', self.onboarding_step + 1) unless self.onboarding_complete?
  end

    # Onboarding steps - hardcoded here at 9
  def onboarding_complete?
    self.onboarding_step == Startup.num_onboarding_steps
  end

  def self.num_onboarding_steps
    9
  end

  def self.industry_select_options
    Settings.startup_options.industry
  end

  def self.stage_select_options
    Settings.startup_options.stage.to_hash.stringify_keys.map{|k,v| [k,v]}
  end

  def self.company_goal_select_options
    Settings.startup_options.company_goal.to_hash.stringify_keys.map{|k,v| [k,v]}
  end

  def self.growth_model_select_options
    Settings.startup_options.growth_model.to_hash.stringify_keys.map{|k,v| [k,v]}
  end

  protected

  def check_video_urls_are_valid
    err = false
    if !intro_video_url.blank? and !Youtube.valid_url?(intro_video_url)
      self.errors.add(:intro_video_url, 'invalid Youtube URL')
      err = true
    end
    err
  end
end
