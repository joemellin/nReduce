class Startup < ActiveRecord::Base
  has_many :team_members, :class_name => 'User'
  has_many :checkins
  belongs_to :main_contact, :class_name => 'User'
  belongs_to :meeting
  has_many :relationships
  has_many :awesomes, :through => :checkins
  has_many :invites
  has_many :invited_team_members, :through => :invites, :class_name => 'User'

  attr_accessible :name, :team_size, :website_url, :main_contact_id, :phone, :growth_model, :stage, :company_goal, :meeting_id, :one_liner, :active, :launched_at, :industry_list, :technology_list, :ideology_list, :industry, :intro_video_url, :elevator_pitch, :logo, :remote_logo_url, :logo_cache, :remove_logo

  validates_presence_of :intro_video_url, :if => lambda {|startup| startup.onboarding_complete? }
  validates_presence_of :name
  validate :check_video_urls_are_valid

  acts_as_taggable_on :industries, :technologies, :ideologies

  mount_uploader :logo, ImageUploader # carrierwave file uploads
  #has_attached_file :logo, {:default_url => "http://new.nreduce.com/images/coavatar_:style.png"}.merge(Nreduce::Application.config.paperclip_config)

  #validates_attachment :logo, :content_type => { :content_type => ['image/jpg', 'image/png', 'image/jpeg', 'image/gif'] }, 
                             # :size => {:in => 0..500.kilobytes}

  scope :is_public, where(:public => true)
  scope :launched, where('launched_at IS NOT NULL')
  scope :with_intro_video, where('intro_video_url IS NOT NULL')
  scope :onboarded, lambda { where(:onboarding_step => Startup.num_onboarding_steps) }

    # Startups this one is connected to (approved status)
    # uses cache
  def connected_to
    Relationship.all_connections_for(self)
  end

    # Relationships this startup has requested with others
    # not cached
  def requested_relationships
    Relationship.all_requested_relationships_for(self)
  end

    # relationships that other startups have requested with this startup
    # not cached
  def pending_relationships
    Relationship.all_pending_relationships_for(self)
  end

    # Returns true if these two startups are connected in an approved relationship
    # uses cache
  def connected_to?(startup)
    self.connected_to_id?(startup.id)
  end

  def connected_to_id?(startup_id)
    Relationship.all_connection_ids_for(self).include?(startup_id)
  end

    # Returns true if these two starts are connected, or if the provided startup requested to be connected to this startup
    # not cached
  def connected_or_pending_to?(startup)
    # check reverse direction because we need to see if pending request is coming from other startup
    r = Relationship.between(startup, self)
    return true if r and (r.pending? or r.approved?)
    false
  end

   # Returns the checkin for this week (or if Sun/Mon, it checks for last week's checkin)
  def current_checkin
    checkins.ordered.where(['created_at > ?', Time.now - 1.week]).first
  end

  def self.named(name)
    Startup.find_by_name(name)
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

  def self.stages
    {1 => "Idea", 
    2 => "Prototype",
    3 => "Private Alpha/Beta",
    4 => "Launched",
    6 => "Generating Revenue/Scaling"}
  end

  def self.growth_models
    {1 => "Not Sure Yet :)",
    2 => "Viral",
    3 => "SEO",
    4 => "Advertising",
    5 => "Partnerships",
    6 => "SMB Sales",
    7 => "Enterprise Sales"}
  end
  
  def self.company_goals
    {1 => "Fun Project - Chatroulette",
    2 => "Life Style Business - 4 Hour Workweek",
    3 => "Steady Revenue - 37Signals",
    4 => "Improve Society - Kiva",
    5 => "Big Exit - Facebook"}
  end

  def self.industry_select_options
    Settings.startup_options.industry
  end

  def self.stage_select_options
    Startup.stages.map{|k,v| [v,k]}
  end

  def self.company_goal_select_options
    Startup.company_goals.map{|k,v| [v,k]}
  end

  def self.growth_model_select_options
    Startup.growth_models.map{|k,v| [v,k]}
  end

  def self.tags_by_startup_id(startups = [])
    tags_by_startup_id = {}
    taggings = ActsAsTaggableOn::Tagging.where(:taggable_type => 'Startup').includes(:tag)
    taggings = taggings.where(:taggable_id => startups.map{|s| s.id }) unless startups.blank?
    taggings.each do |tagging|
      tags_by_startup_id[tagging.taggable_id] ||= []
      tags_by_startup_id[tagging.taggable_id] << tagging.tag
    end
    tags_by_startup_id
  end

    # Generates stats for all active startsup (onboarded)
    # of pending relationships
    # of approved relationships
    # of rejected relationships
    # of comments given
    # of comments received
  def self.generate_stats
    ret = {}
    startups = Startup.where(:onboarding_step => Startup.num_onboarding_steps)
    comments_by_user_id = Comment.group('user_id').count
    comments_by_checkin_id = Comment.group('checkin_id').count
    startups.each do |s|
      data = {:name => s.name}
      rel = s.relationships
      cs = s.checkins
      data[:pending_relationships] = Relationship.where(:connected_with_id => s.id).pending.count
      data[:approved_relationships] = rel.inject(0){|num, r| r.approved? ? num + 1 : num }
      data[:rejected_relationships] = rel.inject(0){|num, r| r.rejected? ? num + 1 : num }
      data[:checkins_completed] = cs.inject(0){|num, c| c.completed? ? num + 1 : num }
      data[:comments_given] = s.team_members.inject(0){|num, tm| !comments_by_user_id[tm.id].blank? ? num + comments_by_user_id[tm.id] : num }
      data[:comments_received] = cs.inject(0){|num, c| !comments_by_checkin_id[c.id].blank? ? num + comments_by_checkin_id[c.id] : num }
      ret[s.id] = data
    end
    ret
  end

  def self.generate_stats_csv
    stats = Startup.generate_stats
    CSV.generate do |csv|
      csv << ['Link', 'ID', 'Name', 'Pending Relationships', 'Approved Relationships', 'Rejected Relationships', 'Checkins Completed', 'Comments Given', 'Comments Received']
      stats.each do |startup_id, data|
        csv << ['http://new.nreduce.com/startups/' + startup_id.to_s, startup_id, data[:name], data[:pending_relationships], data[:approved_relationships], data[:rejected_relationships], data[:checkins_completed], data[:comments_given], data[:comments_received]]
      end
    end
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
