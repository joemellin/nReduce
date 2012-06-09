class Startup < ActiveRecord::Base
  has_many :team_members, :class_name => 'User'
  has_many :checkins
  belongs_to :main_contact, :class_name => 'User'
  belongs_to :meeting

  attr_accessible :name, :team_size, :website_url, :main_contact_id, :phone, :growth_model, :stage, :company_goal, :meeting_id, :one_liner, :active, :launched_at, :industry_list, :technology_list, :ideology_list, :industry

  serialize :team_members

  validates_presence_of :name
  validate :check_video_urls_are_valid

  acts_as_taggable_on :industries, :technologies, :ideologies

  # Use S3 for production
  # http://blog.tristanmedia.com/2009/09/using-amazons-cloudfront-with-rails-and-paperclip/
  if Rails.env.production?
    Settings.paperclip_config.merge!({
      :storage => 's3',
      :s3_credentials => Settings.aws.s3,
      :s3_headers => { 'Expires' => 1.year.from_now.httpdate },
      :default_url => "http://www.nreduce.com/assets/avatar_:style.png",
      :s3_protocol => 'https'
    })
  end

  has_attached_file :logo, Settings.paperclip_config

  scope :launched, where('launched_at IS NOT NULL')
  scope :with_intro_video, where('intro_video_url IS NOT NULL')

     # Hack - doesn't check the batch, just finds the week for this time
  def checked_in_this_week?
    checkin = current_checkin
    return !checkin.blank? ? checkin.submitted? : false
  end

  def current_checkin
    return checkins.where(:week_id => Week.id_for_time(Time.now)).first
    return nil
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
    return Settings.startup_options.industry
    Settings.startup_options.stage.map{|k,v| [v,k]}
  end

  def self.company_goal_select_options
    return Settings.startup_options.industry
    Settings.startup_options.company_goal.map{|k,v| [v,k]}
  end

  def self.growth_model_select_options
    return Settings.startup_options.industry
    Settings.startup_options.growth_model.map{|k,v| [v,k]}
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
