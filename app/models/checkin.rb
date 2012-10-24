class Checkin < ActiveRecord::Base
  obfuscate_id :spin => 284759320
  belongs_to :startup
  belongs_to :user # the user logged in who created check-in
  belongs_to :measurement
  belongs_to :before_video, :class_name => 'Video', :dependent => :destroy
  belongs_to :after_video, :class_name => 'Video', :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :awesomes, :as => :awsm, :dependent => :destroy
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessible :start_focus, :start_why, :start_video_url, :end_video_url, :end_comments, 
    :startup_id, :start_comments, :startup, :measurement_attributes, 
    :before_video_attributes, :after_video_attributes, :accomplished

  accepts_nested_attributes_for :measurement, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :before_video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :after_video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true

  after_validation :check_submitted_completed_times
  before_save :notify_user
  before_create :assign_week
  after_save :reset_startup_checkin_cache
  after_destroy :reset_startup_checkin_cache

  validates_presence_of :startup_id
  validates_presence_of :start_focus, :message => "can't be blank", :if => lambda { Checkin.in_before_time_window? }
  validates_presence_of :before_video, :message => "can't be blank", :if => lambda { Checkin.in_before_time_window? }
  validates_presence_of :after_video, :message => "can't be blank", :if =>  lambda { Checkin.in_after_time_window? }
  validates_inclusion_of :accomplished, :in => [true, false], :message => "must be selected", :if => lambda { Checkin.in_after_time_window? }
  #validate :check_video_urls_are_valid
  validate :measurement_is_present_if_launched

  scope :ordered, order('created_at DESC')
  scope :completed, where('completed_at IS NOT NULL')

  @queue = :checkin_message

    # Returns hash of {:startup_id => current_checkin}
  def self.current_checkin_for_startups(startups = [])
    return {} if startups.blank?
    # next_checkin = Checkin.next_checkin_type_and_time
    if Checkin.in_after_time_window?
      checkins = Checkin.where(:startup_id => startups.map{|s| s.id }).where(['created_at > ?', Checkin.prev_after_checkin])
    else # if in before checkin or in the week after, get prev week's checkin start time
      start_time = Checkin.prev_after_checkin - 24.hours
      checkins = Checkin.where(:startup_id => startups.map{|s| s.id }).where(['completed_at > ?', start_time])
    end
    checkins.inject({}){|res, e| res[e.startup_id] = e; res }
  end

  # Returns a given number of checkins for startups
  def self.for_startups_by_week(startups = [], num_weeks = 4)
    return {} if startups.blank?
    week = Week.integer_for_time(Time.now)
    1.upto(num_weeks){ week = Week.previous(week) }
    alphabetical_ids = startups.sort{|a,b| a.name.downcase <=> b.name.downcase }.map{|s| s.id }
    checkins = Checkin.where(:startup_id => alphabetical_ids).where(['week >= ?', week]).order('week DESC').includes(:measurement).all
    c_by_week = Hash.by_key(checkins, :week, nil, true)
    # Sort each week of checkins by startup name
    c_by_week.each do |week, checkins|
      checkins.sort_by!{|checkin| alphabetical_ids.index(checkin.startup_id) }
    end
    c_by_week
  end

  def self.in_a_checkin_window?
    self.in_before_time_window? or self.in_after_time_window?
  end

    # Returns true if in the time window where startups can do 'before' check-in
  def self.in_before_time_window?
    # tues from 4pm - wed 4pm
    now = Time.now
    next_before = Checkin.next_before_checkin
    return true if now < next_before and now > (next_before - 24.hours)
    false
  end

    # Returns true if in the time window where startups can do 'after' check-in
  def self.in_after_time_window?
    # monday from 4pm - tue 4pm
    now = Time.now
    next_after = Checkin.next_after_checkin
    return true if now < next_after and now > (next_after - 24.hours)
    false
  end

    # Returns Time of next before checkin: Tue 4pm - Wed 4pm
  def self.next_after_checkin
    t = Time.now
    # Are we in Mon or tue? - if so next before checkin is this week
    if t.monday? or (t.tuesday? and t.hour < 16)
      return t.beginning_of_week + 1.day + 16.hours
    else
      # Otherwise it's next week
      return t.beginning_of_week + 1.week + 1.day + 16.hours
    end
  end

   # Returns Time of next after checkin: Mon 4pm - Tue 4pm
  def self.next_before_checkin
    t = Time.now
    # Are we in Mon or tue? - if so next before checkin is this week
    if t.monday? or t.tuesday? or (t.wednesday? and t.hour < 16)
      t.beginning_of_week + 2.days + 16.hours
    else
      # Otherwise it's next week
      t.beginning_of_week + 1.week + 2.days + 16.hours
    end
  end

  def self.prev_after_checkin
    self.next_after_checkin - 1.week
  end

  def self.prev_before_checkin
    self.next_before_checkin - 1.week
  end

  # Returns an array with the next checkin type and time, ex: [:before, Time obj]
  def self.next_checkin_type_and_time
    before = Checkin.next_before_checkin
    after = Checkin.next_after_checkin
    if before < after
      {:type => :before, :time => before}
    else
      {:type => :after, :time => after}
    end
  end

  # Pass in a timestamp and this will return the start (4pm on Tue) of that checkin's week
  def self.week_start_for_time(time)
    # reset to tuesday
    if time.sunday? or time.monday? or (time.tuesday? and time.hour < 16)
      time = time.beginning_of_week - 5.days
    else
      time = time.beginning_of_day - time.days_to_week_start.days + 2.days
    end
    time += 16.hours # set it at 4pm
    time
  end

  # Pass in a timestamp and this will return the current week description for that timestamp
  # ex: Jul 5 to Jul 12
  def self.week_for_time(time)
    # reset to tuesday
    beginning_of_week = Checkin.week_start_for_time(time)
    Week.for_time(beginning_of_week)
  end

  def self.week_integer_for_time(time)
    Week.integer_for_time(Checkin.week_start_for_time(time))
  end

  # Pass in a week integer (ex: 20126) and this will pass back the week before, 20125
  def self.previous_week(week)
    Week.previous(week)
  end

  # Queues up 'before' email to be sent to all active users
  def self.send_before_checkin_email
    users_with_startups = User.where('email IS NOT NULL').where(:startup_id => Startup.select('id').account_complete.map{|s| s.id })

    users_with_startups.each do |u|
      Resque.enqueue(Checkin, :before, u.id) if u.account_setup? && u.email_for?('docheckin')
    end
  end

  # Queues up 'after' email to be sent to all active users
  def self.send_after_checkin_email
    users_with_startups = User.where('email IS NOT NULL').where(:startup_id => Startup.select('id').account_complete.map{|s| s.id })

    users_with_startups.each do |u|
      Resque.enqueue(Checkin, :after, u.id) if u.account_setup? && u.email_for?('docheckin')
    end
  end

  # Mails checkin message
  # Checkin type can be either :before, :after
  def self.perform(checkin_type, user_id)
    if checkin_type.to_sym == :before
      UserMailer.before_checkin_reminder(User.find(user_id)).deliver
    elsif checkin_type.to_sym == :after
      UserMailer.after_checkin_reminder(User.find(user_id)).deliver
    end
  end

  # Returns an array of checkin history for this startup, each array element being whether they completed a before/after video
  # ex: [[true, false], [false, false], [true, false]]
  def self.history_for_startup(startup)
    arr = []
    week = nil
    checkins = startup.checkins.order('created_at DESC')
    return arr if checkins.blank?
    # add blank elements at the beginning until they've done a checkin - start at end of prev after checkin
    current_week = Checkin.week_integer_for_time(Checkin.prev_after_checkin)
    checkins.each do |c|
      while current_week != c.week
        arr << [false, false]
        # move current week back one week until we hit the next checkin
        current_week = Week.previous(current_week)
      end
      arr << [c.submitted?, c.completed?]
      current_week = Week.previous(current_week)
    end
    arr
  end

  def self.num_consecutive_checkins_for_startup(startup)
    history = Checkin.history_for_startup(startup)
    consecutive_checkins = longest_streak = 0
    prev_week = false
    history.each do |before, after|
      # If the checkin has a before and after video count it
      if before and after
        # Starting off - first week
        if prev_week.blank?
          consecutive_checkins += 1
        else
          consecutive_checkins += 1
        end
        prev_week = true
      else # otherwise reset consecutive checkins
        longest_streak = consecutive_checkins if consecutive_checkins > longest_streak
        consecutive_checkins = 0
      end
    end
    # If streak was never broken need to populate longest streak
    longest_streak = consecutive_checkins if consecutive_checkins > longest_streak
    longest_streak
  end

  # Takes youtube urls and converts to our new db-backed format (and uploads to vimeo)
  def convert_to_new_video_format
    return true if self.before_video.present? && self.after_video.present?
    if self.start_video_url.present? && self.before_video.blank?
      ext_id = Youtube.id_from_url(self.start_video_url)
      y = Youtube.where(:external_id => ext_id).first
      y ||= Youtube.new
      y.external_id = ext_id
      y.user = self.user
      if y.save
        self.before_video = y
        self.save(:validate => false)
      else
        puts "Couldn't save before video: #{y.errors.full_messages}"
      end
    end
    if self.end_video_url.present? && self.after_video.blank?
      ext_id = Youtube.id_from_url(self.end_video_url)
      y = Youtube.where(:external_id => ext_id).first
      y ||= Youtube.new
      y.external_id = ext_id
      y.user = self.user
      if y.save
        self.after_video = y
        self.save(:validate => false)
      else
        puts "Couldn't save after video: #{y.errors.full_messages}"
      end
    end
    true
  end

  # Cache # of comments
  def update_comments_count
    self.comment_count = self.comments.not_deleted.count
    self.save(:validate => false) # don't require validations in case we're during check-in window with requirements
  end

  def time_label
    Checkin.week_for_time(self.created_at || Time.now)
  end

  def time_window
    Week.window_for_integer(self.week)
  end

  def submitted?
    !submitted_at.blank?
  end

  def completed?
    !completed_at.blank?
  end

  # Returns true if the 'before' section of the checkin was completed
  def before_completed?
    !self.start_focus.blank? and (!self.start_video_url.blank? || !self.before_video.blank?)
  end

  # Returns true if the 'after' section of the checkin was completed
  def after_completed?
    !self.end_video_url.blank? || !self.after_video.blank?
  end

  def self.video_url_is_unique?(url)
    cs = Checkin.where(:start_video_url => url).or(:end_video_url => url)
    return cs.map{|c| c.id }.delete_if{|id| id == self.id }.count > 0
  end

    # Assigns week for this checkin, ex: 20125 is week 5 of 2012
    # uses created at date, or if not yet saved, current time
  def assign_week
    self.week = Checkin.week_integer_for_time(self.created_at || Time.now)
    true
  end

  def check_video_urls_are_valid
    success = true
    if !start_video_url.blank? and !Youtube.valid_url?(start_video_url)
      self.errors.add(:start_video_url, 'invalid Youtube URL')
      success = false
    end
    if !end_video_url.blank? and !Youtube.valid_url?(end_video_url)
      self.errors.add(:end_video_url, 'invalid Youtube URL')
      success = false
    end
    success
  end

  protected

  def reset_startup_checkin_cache
    self.startup.reset_current_checkin_cache
  end

  def check_submitted_completed_times
    if self.errors.blank?
      self.submitted_at = Time.now if !self.submitted? and self.before_completed?
      self.completed_at = Time.now if !self.completed? and self.after_completed?
    end
    true
  end

  def measurement_is_present_if_launched
    if self.after_completed? && self.startup.launched?
      if self.measurement.blank? || self.measurement.value.blank?
        self.errors.add(:measurement, 'needs to be added since you are launched - to measure traction & progress')
        return false
      end
    end
    true
  end

  def notify_user
    # only notify first time it changes state to completed
    Notification.create_for_new_checkin(self) if self.completed? and self.completed_at_changed?
  end
end
