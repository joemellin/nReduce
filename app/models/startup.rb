class Startup < ActiveRecord::Base
  obfuscate_id :spin => 29406582
  include Connectable # methods for relationships
  has_paper_trail :ignore => [:setup, :cached_industry_list]
  belongs_to :main_contact, :class_name => 'User'
  belongs_to :meeting
  belongs_to :intro_video, :class_name => 'Video', :dependent => :destroy
  belongs_to :pitch_video, :class_name => 'Video', :dependent => :destroy
  has_many :team_members, :class_name => 'User'
  has_many :checkins, :dependent => :destroy
  has_many :awesomes, :through => :checkins
  has_many :invites, :dependent => :destroy
  has_many :nudges, :dependent => :destroy
  has_many :notifications, :as => :attachable, :dependent => :destroy
  has_many :user_actions, :as => :attachable, :dependent => :destroy
  has_many :initiated_relationships, :as => :entity, :class_name => 'Relationship', :dependent => :destroy # relationships this startup began
  has_many :received_relationships, :as => :connected_with, :class_name => 'Relationship', :dependent => :destroy # relationships others began with this startup
  has_many :instruments, :dependent => :destroy
  has_many :measurements, :through => :instruments
  has_many :slide_decks, :dependent => :destroy
  has_many :screenshots, :dependent => :destroy
  has_many :ratings
  has_many :questions

  attr_accessible :name, :investable, :team_size, :website_url, :main_contact_id, :phone, 
    :growth_model, :stage, :company_goal, :meeting_id, :one_liner, :active, :launched_at, 
    :industry_list, :technology_list, :ideology_list, :industry, :intro_video_url, :elevator_pitch, 
    :logo, :remote_logo_url, :logo_cache, :remove_logo, :checkins_public, :pitch_video_url, 
    :investable, :screenshots_attributes, :business_model, :founding_date, :market_size

  accepts_nested_attributes_for :screenshots, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :intro_video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :pitch_video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true

  #validates_presence_of :intro_video_url, :if => lambda {|startup| startup.onboarding_complete? }
  validates_presence_of :name
  validate :check_video_urls_are_valid
  validates_presence_of :one_liner, :if => :created_but_not_setup_yet?
  validates_presence_of :elevator_pitch, :if => :created_but_not_setup_yet?
  validates_presence_of :industry_list, :if => :created_but_not_setup_yet?
  #validates_presence_of :growth_model, :if => :created_but_not_setup_yet?
  #validates_presence_of :stage, :if => :created_but_not_setup_yet?
  #validates_presence_of :company_goal, :if => :created_but_not_setup_yet?

  before_save :format_url
  before_save :reset_cached_elements
  after_create :initiate_relationships_from_invites

  acts_as_taggable_on :industries, :technologies, :ideologies

  mount_uploader :logo, LogoUploader # carrierwave file uploads

  scope :is_public, where(:public => true)
  scope :launched, where('launched_at IS NOT NULL')
  scope :with_intro_video, where('intro_video_url IS NOT NULL')
  scope :with_logo, where('logo IS NOT NULL')

  bitmask :setup, :as => [:profile, :invite_team_members, :intro_video]

  NUM_SCREENSHOTS = 4

  # Uses Sunspot gem with Solr backend. Docs: http://outoftime.github.com/sunspot/docs/index.html
  # https://github.com/outoftime/sunspot
  searchable do
    # full-text search fields - can add :stored => true if you don't want to hit db
    text :name, :boost => 4.0
    text :location do
      team_members.map{|tm| tm.location }.delete_if{|l| l.blank? }
    end
    text :industries_cached, :stored => true do
      self.industries.map{|t| t.name.titleize }.join(', ')
    end
    text :website_url
    text :one_liner

    # filterable fields
    integer :id
    integer :stage
    integer :company_goal
    boolean :onboarded do
      self.account_setup?
    end
    double  :rating
    boolean :public
    boolean :investable
    integer :industry_tag_ids, :multiple => true, :stored => true do
      self.industries.map{|t| t.id }
    end
    string :sort_name do
      name.downcase.gsub(/^(an?|the)/, '')
    end
    integer :num_checkins do
      self.checkins.count
    end
    integer :num_pending_relationships do
      self.received_relationships.pending.count
    end
  end

  def self.registration_open?
    true
  end

  def self.community_status
    {0 => 'Quiet', 1 => 'Helpful', 2 => 'Very Helpful'}
  end

  def self.named(name)
    Startup.find_by_name(name)
  end

  def self.nreduce_id
    Cache.get('nreduce_id', nil, true){
      Startup.named('nreduce').to_param
    }
  end

  def launched?
    !self.launched_at.blank?
  end

  def launched!
    self.update_attribute('launched_at', Time.now)
  end

  def mentors
    self.connected_to('User')
  end

   # Returns the checkin for this nReduce week (Tue 4pm - next Tue 4pm)
  def current_checkin
    checkins.ordered.where(['created_at > ?', Checkin.prev_after_checkin]).first
  end

  def number_of_consecutive_checkins
    Checkin.num_consecutive_checkins_for_startup(self)
  end

    # Returns hash of all requirements to be allowed to search for a mentor - and whether this startup has met them
  def mentor_elements
    consecutive_checkins = self.number_of_consecutive_checkins
    num_awesomes = self.awesomes.count
    my_rating = self.rating.blank? ? 0 : self.rating
    profile_completeness = self.profile_completeness_percent
    elements = {
      :consecutive_checkins => { :value => consecutive_checkins, :passed => consecutive_checkins >= 4 },
      :num_awesomes => {:value => num_awesomes, :passed => num_awesomes >= 10 },
      :community_status => {:value => my_rating, :passed => my_rating >= 1.0 },
      :profile_completeness => {:value => profile_completeness, :passed => profile_completeness == 1.0 }
    }
    passed = 0
    elements.each{|name, e| passed += 1 if e[:passed] == true }
    elements[:total] = {:value => "#{passed} of #{elements.size}", :passed => passed == elements.size}
    elements
  end

   # Returns true if mentor elements all pass and they haven't invited an nreduce mentor in the last week
  def can_invite_mentor?
    can_invite = true
    relationships = self.relationships.startup_to_user.approved.where(['created_at > ?', Time.now - 1.week]).includes(:connected_with)
    relationships.each do |r|
      can_invite = false if r.connected_with.roles?(:nreduce_mentor)
    end
    (mentor_elements[:total][:passed] == true) and can_invite
  end

  # They can enter from their weekly class if they have completed their profile and are connected to four other startups
  def can_enter_nreduce?
    self.profile_completeness_percent == 1.0 && self.connected_to_ids('Startup').size >= 4
  end

    # Calculates profile completeness for all factors
    # Returns total percent out of 1 (eg: 0.25 for 25% completeness)
  def profile_completeness_percent
    Cache.get(['profile_c', self], nil, true){
      total = completed = 0.0
      self.profile_elements.each do |element, is_completed|
        total += 1.0
        # Team member completeness %
        if is_completed.is_a? Float
          completed += is_completed
        # Boolean completeness
        else
          completed += 1.0 if is_completed
        end
      end
      (completed / total).round(2)
    }.to_f
  end

    # Returns hash of all elements + each team member's completeness as 
  def profile_elements
    elements = {
      :elevator_pitch => (!self.elevator_pitch.blank? && (self.elevator_pitch.size > 10)), 
      :markets => !self.cached_industry_list.blank?,
      :one_liner => self.one_liner.present?
    }
    self.team_members.each do |tm|
      elements[tm.name.to_url.to_sym] = tm.profile_completeness_percent
    end
    #elements[:at_least_four_connections] = self.connected_to_ids('Startup').size >= 4
    elements
  end

  def investor_profile_completeness_percent
    total = completed = 0.0
    completed += 1 unless self.pitch_video_url.blank?
    total += 1
    self.team_members.each do |tm|
      completed += 1 unless tm.intro_video_url.blank?
      total += 1
    end
    num_screenshots = self.screenshots.count
    completed += (num_screenshots.to_f / Startup::NUM_SCREENSHOTS.to_f) unless num_screenshots == 0
    total += 1
    (completed / total).round(2)
  end

  def self.stages
    {1 => "Idea", 
    2 => "Prototype",
    3 => "Private Alpha/Beta",
    4 => "Launched",
    5 => "Generating Revenue/Scaling"}
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
    virtual_meeting_id = Meeting.where(:location_name => 'Virtual').first.id
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
      meeting_ids = s.team_members.map{|tm| tm.meeting_id }.uniq.delete_if{|m| m.nil? }
      data[:virtual] = (meeting_ids.include?(virtual_meeting_id) or meeting_ids.blank?) ? true : false
      data[:rating] = s.rating
      ret[s.id] = data
    end
    ret
  end

  def self.generate_stats_csv
    stats = Startup.generate_stats
    CSV.generate do |csv|
      csv << ['Link', 'ID', 'Name', 'Pending Relationships', 'Approved Relationships', 'Rejected Relationships', 'Checkins Completed', 'Comments Given', 'Comments Received', 'Rating']
      stats.each do |startup_id, data|
        csv << ['http://new.nreduce.com/startups/' + startup_id.to_s, startup_id, data[:name], data[:pending_relationships], data[:approved_relationships], data[:rejected_relationships], data[:checkins_completed], data[:comments_given], data[:comments_received], data[:rating]]
      end
    end
  end

  # converts url to uri - and adds http if necessary
  def website_url_to_uri
    begin
      URI.parse(self.website_url)
    rescue
      nil
    end
  end

  def format_url
    return true if website_url.blank?
    if website_url.match(/^https?:\/\//) == nil
      self.website_url = "http://#{website_url}"
    end
    true
  end

  def invited_team_members!
    self.setup << :invite_team_members
    save
  end

  # Forces all setup complete actions to be set and saved for this startup and team members
  def force_setup_complete!
    self.setup = [:profile, :invite_team_members, :intro_video]
    self.save
    c = 0
    self.team_members.each do |u|
      # only suggest startups once, for first team member
      u.setup_complete!(c == 0, true)
      c += 1
    end
    true
  end

    # Returns true if the user has set everything up for the account (otherwise forces user to go through flow)
  def account_setup?
    self.setup?(:profile, :invite_team_members, :intro_video)
  end

  # scope for a completed account
  def self.account_complete
    with_setup(:profile, :invite_team_members, :intro_video)
  end

  # Returns the current controller / action for setup - to see if they need to set anything up
  # first checks setup field so we don't have to perform db queries if they've completed that step
  def account_setup_action
    return [:complete] if account_setup?
    return [:startups, :new] if new_record?
    if !setup?(:profile)
      if !valid? # don't check for completeness yet because that'll force team member stuff
        return [:startups, :edit]
      else
        self.setup << :profile
        self.save
      end
    end
    if !setup?(:invite_team_members)
      return [:startups, :invite_team_members]
    end
    if !setup?(:intro_video)
      if !self.intro_video_url.blank? && Youtube.valid_url?(intro_video_url)
        self.setup << :intro_video
        self.save
      else
        return [:startups, :intro_video] # key is before video, but changing action to team intro video
      end
    end
    # If we just completed everything pass that back
    return [:complete] if account_setup?
    nil
  end

   # Takes youtube urls and converts to our new db-backed format (and uploads to vimeo)
  def convert_to_new_video_format
    return true if self.pitch_video.present? && self.intro_video.present?
    if self.intro_video_url.present? && self.intro_video.blank?
      ext_id = Youtube.id_from_url(self.intro_video_url)
      y = Youtube.where(:external_id => ext_id).first
      y ||= Youtube.new
      y.external_id = ext_id
      y.user = self.user
      if y.save
        self.intro_video = y
        self.save(:validate => false)
      else
        puts "Couldn't save intro video: #{y.errors.full_messages}"
      end
    end
    if self.pitch_video_url.present? && self.pitch_video.blank?
      ext_id = Youtube.id_from_url(self.pitch_video_url)
      y = Youtube.where(:external_id => ext_id).first
      y ||= Youtube.new
      y.external_id = ext_id
      y.user = self.user
      if y.save
        self.pitch_video = y
        self.save(:validate => false)
      else
        puts "Couldn't save pitch video: #{y.errors.full_messages}"
      end
    end
    true
  end

  def cached_team_member_ids
    ids = Cache.get(['tm_ids', self.id]){
      User.where(:startup_id => self.id).map{|u| u.id }  
    }
  end

  protected

  def reset_cached_elements
    Cache.delete(['profile_c', self])
    true
  end

  def created_but_not_setup_yet?
    !self.new_record? && !self.account_setup?
  end

  # If they were invited by another startup, establish a relationship
  # TODO: Bug: if this user was invited by a startup in the past, this will always connect them to every startup they got invited from
  # - I just haven't thought of a good solution. session storage of accepted invite isn't robust enough.
  def initiate_relationships_from_invites
    Invite.where(:to_id => self.team_members.map{|tm| tm.id }).each do |i|
      next if i.startup.blank?
      rel = Relationship.start_between(i.startup, self, :startup_startup, true)
      rel.approve! unless rel.blank?
    end
    true
  end

  def check_video_urls_are_valid
    err = false
    if !intro_video_url.blank? and !Youtube.valid_url?(intro_video_url)
      self.errors.add(:intro_video_url, 'invalid Youtube URL')
      err = true
    end
    if !pitch_video_url.blank? and !Youtube.valid_url?(pitch_video_url)
      self.errors.add(:pitch_video_url, 'invalid Youtube URL')
      err = true
    end
    err
  end
end
