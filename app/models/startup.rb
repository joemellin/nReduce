class Startup < ActiveRecord::Base
  include Connectable # methods for relationships
  include Onboardable
  has_many :team_members, :class_name => 'User'
  has_many :checkins
  belongs_to :main_contact, :class_name => 'User'
  belongs_to :meeting
  has_many :awesomes, :through => :checkins
  has_many :invites
  has_many :nudges
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessible :name, :team_size, :website_url, :main_contact_id, :phone, :growth_model, :stage, :company_goal, :meeting_id, :one_liner, :active, :launched_at, :industry_list, :technology_list, :ideology_list, :industry, :intro_video_url, :elevator_pitch, :logo, :remote_logo_url, :logo_cache, :remove_logo, :checkins_public

  validates_presence_of :intro_video_url, :if => lambda {|startup| startup.onboarding_complete? }
  validates_presence_of :name
  validate :check_video_urls_are_valid

  before_save :format_url

  acts_as_taggable_on :industries, :technologies, :ideologies

  mount_uploader :logo, LogoUploader # carrierwave file uploads

  scope :is_public, where(:public => true)
  scope :launched, where('launched_at IS NOT NULL')
  scope :with_intro_video, where('intro_video_url IS NOT NULL')

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
    integer :stage
    integer :company_goal
    integer :onboarding_step
    double  :rating
    boolean :public
    integer :industry_tag_ids, :multiple => true, :stored => true do
      self.industries.map{|t| t.id }
    end
    string :sort_name do
      name.downcase.gsub(/^(an?|the)/, '')
    end
  end

  def self.registration_open?
    false
  end

  def self.community_status
    {0 => 'Inactive', 1 => 'Helpful', 2 => 'Very Helpful'}
  end

  def self.named(name)
    Startup.find_by_name(name)
  end

  def self.nreduce_id
    Cache.get('nreduce_id', nil, true){
      Startup.named('nreduce').id
    }
  end

  def mentors
    self.connected_to('User')
  end

   # Returns the checkin for this nReduce week (Tue 4pm - next Tue 4pm)
  def current_checkin
    checkins.ordered.where(['created_at > ?', Checkin.prev_after_checkin]).first
  end

    # Returns hash of all requirements to be allowed to search for a mentor - and whether this startup has met them
  def mentor_elements
    consecutive_checkins = 3
    num_awesomes = self.awesomes.count
    my_rating = self.rating.blank? ? 0 : self.rating
    profile_completeness = self.profile_completeness_percent
    passed = 0
    elements = {
      :consecutive_checkins => { :value => consecutive_checkins, :passed => consecutive_checkins >= 4 },
      :num_awesomes => {:value => num_awesomes, :passed => num_awesomes >= 10 },
      :community_status => {:value => my_rating, :passed => my_rating >= 1.0 },
      :profile_completeness => {:value => profile_completeness, :passed => profile_completeness == 1.0 }
    }
    elements.each{|name, e| passed += 1 if e[:passed] == true }
    elements[:total] = {:value => "#{passed} of #{elements.size}", :passed => passed == elements.size}
    elements[:total][:passed] = true
    elements
  end

   # Returns true if mentor elements all pass and they haven't invited an nreduce mentor in the last week
  def can_invite_mentor?
    (mentor_elements[:total][:passed] == true) and self.invites.to_nreduce_mentors.where(['created_at > ?', Time.now - 1.week])
  end

    # Calculates profile completeness for all factors
    # Returns total percent out of 1 (eg: 0.25 for 25% completeness)
  def profile_completeness_percent
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
  end

    # Returns hash of all elements + each team member's completeness as 
  def profile_elements
    elements = {
      :intro_video => !self.intro_video_url.blank?, 
      :elevator_pitch => (!self.elevator_pitch.blank? and (self.elevator_pitch.size > 10)), 
      :industry => !self.industry_list.blank?,
    }
    self.team_members.each do |tm|
      elements[tm.name.to_url.to_sym] = tm.profile_completeness_percent
    end
    elements
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
