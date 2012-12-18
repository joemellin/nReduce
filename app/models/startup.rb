class Startup < ActiveRecord::Base
  obfuscate_id :spin => 29406582
  include Connectable # methods for relationships
  include Accountable # allows startup to have account (for helpfuls)
  has_paper_trail :ignore => [:setup, :cached_industry_list, :active, :checkin_day, :time_zone]
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
  has_many :requests
  has_many :responses, :through => :requests

  attr_accessible :name, :investable, :team_size, :website_url, :main_contact_id, :phone, 
    :growth_model, :stage, :company_goal, :meeting_id, :one_liner, :active, :launched_at, 
    :industry_list, :technology_list, :ideology_list, :industry, :intro_video_url, :elevator_pitch, 
    :logo, :remote_logo_url, :logo_cache, :remove_logo, :checkins_public, :pitch_video_url, 
    :investable, :screenshots_attributes, :business_model, :founding_date, :market_size, :in_signup_flow, 
    :invites_attributes, :mentorable, :time_zone, :checkin_day
  attr_accessor :in_signup_flow

  accepts_nested_attributes_for :screenshots, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :intro_video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :pitch_video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :invites, :reject_if => proc {|attributes| attributes[:email].blank? }, :allow_destroy => true

  validates_presence_of :name
  validate :check_video_urls_are_valid
  #validates_presence_of :one_liner, :if => :created_but_not_setup_yet?
  #validates_presence_of :elevator_pitch, :if => :created_but_not_setup_yet?
  #validates_presence_of :industry_list, :if => :created_but_not_setup_yet?

  before_validation :encode_pitch_video
  before_save :format_url
  before_save :reset_cached_elements
  after_create :setup_account
  after_create :initiate_relationships_from_invites
  after_create :notify_joe_of_new_startup

  acts_as_taggable_on :industries, :technologies, :ideologies

  mount_uploader :logo, LogoUploader # carrierwave file uploads

  scope :is_public, where(:public => true)
  scope :launched, where('launched_at IS NOT NULL')
  scope :with_intro_video, where('intro_video_url IS NOT NULL')
  scope :with_logo, where('logo IS NOT NULL')
  scope :active, where(:active => true)
  scope :inactive, where(:active => false)

  bitmask :setup, :as => [:profile, :invite_team_members, :intro_video, :goal, :connections]

  NUM_SCREENSHOTS = 4
  # Number of active startups you need
  NUM_ACTIVE_REQUIRED = 6

  # Uses Sunspot gem with Solr backend. Docs: http://outoftime.github.com/sunspot/docs/index.html
  # https://github.com/outoftime/sunspot
  searchable do
    # full-text search fields - can add :stored => true if you don't want to hit db
    text :name, :boost => 4.0, :stored => true
    text :team_member_names do
      team_members.map{|tm| tm.name.downcase }.join(',')
    end

    # filterable fields
    integer :id, :stored => true
    integer :industry_ids, :multiple => true
    boolean :active
    double  :rating
    string :sort_name do
      name.downcase.gsub(/^(an?|the)/, '')
    end
  end

  # Searches all teams and identifies who has checked in the last two weeks (starting at beginning of this current week) - they are marked as active. All others are inactive
  def self.identify_active_teams
    all_ids = Startup.all.map{|s| s.id }
    # Count all startups who have checked in last two weeks. If count is 0, they are inactive
    active = []
    Checkin.where(['created_at > ?', Time.now.beginning_of_week - 2.weeks]).group(:startup_id).count.each do |startup_id, num_checkins|
      active << startup_id if num_checkins > 0
    end
    # Update all startups' state who are not already set correctly
    Startup.transaction do
      Startup.where(:id => active).where(:active => false).each{|s| s.active = true; s.save }
    end
    inactive = all_ids - active
    Startup.transaction do
      Startup.where(:id => inactive).where(:active => true).each{|s| s.active = false; s.save(:validate => false) }
    end
    "#{active.size} Active Teams, #{inactive.size} Inactive Teams"
  end

  def self.last_activated_teams(limit = 3)
    Startup.with_setup(:goal).active.order('activated_at DESC').limit(limit)
  end

  def self.default_checkin_day
    2
  end

  def self.community_status
    {0 => 'Quiet', 1 => 'Helpful', 2 => 'Very Helpful'}
  end

  def self.named(name)
    Startup.find_by_name(name)
  end

  def self.nreduce_id
    Cache.get('nreduce_id', nil, true){
      Startup.named('nreduce').id
    }.to_i
  end

  def self.nreduce_obfuscated_id
    ObfuscateId.hide(Startup.nreduce_id)
  end

  # Returns array for calculating checkin window offset [offset of day it starts from day of week, duration]
  def checkin_offset
    #return @checkin_offset if @checkin_offset.present?
    if self.checkin_day.present? && self.time_zone.present?
      # Calc offset from beginning of week + duration
      @checkin_offset = [self.checkin_day.days, 24.hours]
    else
      @checkin_offset = Checkin.default_offset
    end
    @checkin_offset
  end

  def time_zone_offset
    ActiveSupport::TimeZone[self.time_zone || Settings.default_time_zone].utc_offset
  end

  def launched?
    !self.launched_at.blank?
  end

  def launched!
    self.update_attribute('launched_at', Time.now) if self.launched_at.blank?
  end

  def mentors
    self.connected_to('User')
  end

  def investor_videos
    ([self.pitch_video] + self.team_members.map{|tm| tm.intro_video }).delete_if{|v| v.blank? }
  end

  def self.all_that_can_access_mentors_investors
    ids = Cache.get('s_i_m', 10.minutes){
      startup_ids = []
      Startup.where('investable = 1 OR mentorable = 1').all.map{|s| startup_ids << s.id if s.can_access_mentors_and_investors? }
      startup_ids
    }
    Startup.find(ids)
  end

   # Returns the checkin for this nReduce week (Tue 4pm - next Tue 4pm)
  def current_checkin(reset_cache = false)
    self.reset_current_checkin_cache if reset_cache
    cid = self.current_checkin_id
    Checkin.find(cid) if cid.present?
  end

  def previous_checkin
    prev_at = Checkin.prev_checkin_due_at(self.checkin_offset) - self.checkin_offset.last
    checkins.ordered.where(['created_at < ? AND created_at > ?', prev_at, prev_at - 1.week]).order('created_at DESC').first
  end

  def current_checkin_id
    # expire when next checkin due
    next_due = Checkin.next_checkin_due_at(self.checkin_offset)
    expires_in = next_due - self.checkin_offset.last - Time.current
    Cache.get(['current_checkin', self], expires_in, true){
      must_be_after = Checkin.prev_checkin_due_at(self.checkin_offset) - self.checkin_offset.last
      c = checkins.order('created_at DESC').where(['created_at > ? AND created_at < ?', must_be_after, next_due]).first
      c.id if c.present?
    }
  end

  def reset_current_checkin_cache
    Cache.delete(['current_checkin', self])
  end

   # returns array of [instrument_name, latest_rounded_value]
  def latest_measurement_name_and_value(reset_cache = false)
    self.reset_latest_measurement_cache if reset_cache
    ret = Cache.get(['latest_measurement', self]){
      i = self.instruments.first
      m = i.measurements.ordered.first if i.present?
      m.present? ? [i.name, m.value.round] : []
    }
    ret.present? ? ret : []
  end

  def reset_latest_measurement_cache
    Cache.delete(['latest_measurement', self])
  end

  def number_of_consecutive_checkins
    Checkin.num_consecutive_checkins_for_startup(self)
  end

  # They can enter from their weekly class if they have completed their profile and are connected to four other startups
  def can_enter_nreduce?
    self.profile_completeness_percent == 1.0 && self.connected_to_ids('Startup').size >= 4
  end

      # Returns hash of all elements + each team member's completeness as 
  def profile_elements(show_team_member_details = false)
    elements = {
      #:elevator_pitch => (!self.elevator_pitch.blank? && (self.elevator_pitch.size > 10)), 
      :markets => !self.cached_industry_list.blank?,
      :one_liner => self.one_liner.present?
    }
    self.team_members.each do |tm|
      elements["#{tm.name.possessive} Profile".to_url.to_sym] = show_team_member_details ? tm.profile_elements : tm.profile_completeness_percent
    end
    #elements[:at_least_four_connections] = self.connected_to_ids('Startup').size >= 4
    elements
  end

    # Calculates profile completeness for all factors
    # Returns total percent out of 1 (eg: 0.25 for 25% completeness)
  def profile_completeness_percent
    Cache.get(['profile_c', self], nil, true){
      completed, total = calculate_completeness(self.profile_elements)
      (completed / total).round(2)
    }.to_f
  end

  def investor_mentor_elements
    profile_completeness = self.profile_completeness_percent
    checkin_last_week = self.previous_checkin
    num_screenshots = self.screenshots.count
    elements = {
      :startup_profile => {
        :checked_in_last_week => checkin_last_week.present? && checkin_last_week.completed?,
        :pitch_video => self.pitch_video_url.present?,
        :add_four_screenshots => num_screenshots == 4 ? true : (num_screenshots == 0.0 ? 0.0 : (num_screenshots.to_f / 4.0).round(2))
      }
    }
    elements[:startup_profile].merge!(self.profile_elements(true))
    self.team_members.each do |tm|
      elements["#{tm.name} Intro Video".to_url.to_sym] = tm.intro_video_url.present?
    end
    elements
  end

  def investor_mentor_completeness_percent
    completed, total = calculate_completeness(self.investor_mentor_elements)
    (completed / total).round(2)
  end

  # Will calculate profile completeness on multi-dimensional hash
  # Returns array of [completed, total] float values
  def calculate_completeness(hash, completed = 0.0, total = 0.0)
    hash.each do |k,v|
      if v.is_a?(Hash)
        completed, total = calculate_completeness(v, completed, total)
      else
        if v.is_a?(Float)
          completed += v
        elsif v == true
          completed += 1.0
        end
        total += 1.0
      end
    end
    [completed, total]
  end

  def checkin_day_human
    Date::DAYNAMES[self.checkin_day]
  end

     # Returns true if mentor & investor elements all pass
   # commented out: they haven't invited an nreduce mentor in the last week
  def can_access_mentors_and_investors?
    investor_mentor_completeness_percent == 1.0
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

  def completed_goal!(message = nil, message_from_user = nil)
    self.setup << :goal
    # Set as active as they just did a checkin
    self.active = true
    self.activated_at = Time.now
    connected_to_ids = self.connected_to_ids('Startup')
    team_member_ids = self.team_member_ids
    unless connected_to_ids.present? && connected_to_ids.size > 0
      Startup.last_activated_teams(3).where(['id != ?', self.id]).each do |s|
        r = Relationship.start_between(self, s, :startup_startup, true)
        r.silent = true
        r.introduced = true
        if r.present? && r.valid?
          r.approve!

          # Send message from new founder to these startups
          if message_from_user.present?
            Conversation.create(:to_entity => s,
                                :participant_ids => team_member_ids,
                                :messages => [Message.new(:from_id => message_from_user.id, :content => message)])
          end

          # Now mark them as setup with connections if they've hit six
          s.reload
          if s.connected_to_ids('Startup').size == Startup::NUM_ACTIVE_REQUIRED
            s.setup << :connections
            s.save
          end
        end
      end
    end
    save
  end

  # Forces all setup complete actions to be set and saved for this startup and team members
  def force_setup_complete!
    self.setup = [:profile, :invite_team_members, :intro_video]
    self.active = true
    self.save
    c = 0
    self.team_members.each do |u|
      u.setup_complete!
      c += 1
    end
    true
  end

    # Returns true if the user has set everything up for the account (otherwise forces user to go through flow)
  def account_setup?
    self.setup?(:goal)
  end

  # scope for a completed account
  def self.account_complete
    with_setup(:goal)
  end

  # Returns the current controller / action for setup - to see if they need to set anything up
  # first checks setup field so we don't have to perform db queries if they've completed that step
  def account_setup_action
    return [:complete] if account_setup?
    return [:checkins, :first]
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

  def notify_joe_of_new_startup
    Notification.create_for_new_team_joined(self)
  end

  def reset_cached_elements
    Cache.delete(['profile_c', self]) # reset profile completeness
    Cache.delete(['n_a_s', self]) if self.active_changed? # reset number of active startups
    true
  end

  def created_but_not_setup_yet?
    !in_signup_flow && !self.new_record? && !self.account_setup?
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

  def encode_pitch_video
    if self.pitch_video_url.present? && (self.pitch_video_url_changed? || self.pitch_video_id.blank?)
      self.pitch_video.destroy unless self.pitch_video.blank?
      ext_id = Youtube.id_from_url(self.pitch_video_url)
      self.pitch_video = Youtube.where(:external_id => ext_id).first
      self.pitch_video ||= Youtube.new
      self.pitch_video.external_id = ext_id
      self.pitch_video.user_id = self.team_members.first.id
    end
    true
  end

  def setup_account
    Account.create_for_owner(self)
  end
end
