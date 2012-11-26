class Checkin < ActiveRecord::Base
  obfuscate_id :spin => 284759320
  belongs_to :startup
  belongs_to :user # the user logged in who created check-in
  belongs_to :measurement
  belongs_to :before_video, :class_name => 'Video', :dependent => :destroy
  belongs_to :video, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :awesomes, :as => :awsm, :dependent => :destroy
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessor :next_week_goal
  attr_accessor :previous_step

  attr_accessible :goal, :start_why, :start_video_url, :end_video_url, :notes,
    :startup_id, :start_comments, :startup, :measurement_attributes, 
    :before_video_attributes, :video_attributes, :accomplished,
    :next_week_goal, :video, :startup_attributes
    
  accepts_nested_attributes_for :measurement, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :before_video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true
  accepts_nested_attributes_for :startup, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }

  after_initialize :set_previous_step
  after_validation :add_completed_at_time
  before_save :notify_user
  before_create :assign_week
  before_save :create_next_week_checkin
  after_save :reset_startup_checkin_cache
  after_destroy :reset_startup_checkin_cache

  validates_presence_of :startup_id
  validates_presence_of :video, :message => "can't be blank", :if => Proc.new{|f| f.previous_step >= 1 } 
  validates_inclusion_of :accomplished, :in => [true, false], :message => "must be selected", :if => Proc.new{|f| f.previous_step >= 2 } 
  validate :next_weeks_goal_is_present
  validate :measurement_is_present_if_launched

  scope :ordered, order('created_at DESC')
  scope :completed, where('completed_at IS NOT NULL')

  @queue = :checkin_message

  def self.steps(display_steps_only = false)
    steps = ['Record Video', 'Accomplishments', 'Set Next Week\'s Goal', 'Completed']
    steps.pop if display_steps_only # remove last step if we're displaying them
    steps
  end

  def current_step
    return 0 if self.goal.blank?
    return 1 if self.video.blank? || self.video.new_record?
    return 2 if self.accomplished.nil? # need to add logic for instruments
    return 3 if self.next_week_goal.blank?
    return 4
  end

  def self.add_startups_to_checkin_experiment(startups = [])
    current_ids = Cache.get('checkin_experiment')
    current_ids ||= []
    Cache.set('checkin_experiment', (current_ids + startups.map{|s| s.id }).uniq)
  end

  def self.remove_startups_from_checkin_experiment(startups = [])
    current_ids = Cache.get('checkin_experiment')
    current_ids ||= []
    Cache.set('checkin_experiment', (current_ids - startups.map{|s| s.id }).uniq)
  end

  def self.show_checkin_experiment_for?(startup_id)
    ids = Cache.get('checkin_experiment')
    if ids.present? && ids.is_a?(Array) && ids.include?(startup_id)
      # See if the index is divisible by 2 for a/b test
      return ids.index(startup_id) % 2 == 0
    else
      return false
    end
  end

    # Will queue up emails to be sent to all startups who haven't checked in yet on this day
  def self.email_startups_not_completed_checkin_yet
    return true
    current_day = Time.now.wday
    current_week = Checkin.current_week(Checkin.default_offset)
    # Find all startups that checkin today
    startup_ids = Startup.where(:checkin_day => current_day).map{|s| s.id }
    # Now find which ones were active last week
    ids = Checkin.where(:week => Week.previous(current_week), :startup_id => startup_ids).map{|c| c.startup_id }
    # And then which have completed a checkin this week
    completed_this_week = Checkin.where(:week => current_week, :startup_id => startup_ids).completed.map{|c| c.startup_id }
    not_completed = (ids - completed_this_week).shuffle
    if not_completed.size > 0
      # split them half/half so we can a/b test and send only half an email
      # half = not_completed.size / 2
      # c = 0
      # to_email_ids = []
      # not_completed.each do |id|
      #   to_email_ids << id if c < half
      #   c += 1
      # end
      # not_emailed = not_completed - to_email_ids
      to_email_ids = not_completed
      not_emailed = []
      unless to_email_ids.blank?
        User.where(:startup_id => to_email_ids).each do |u|
          Resque.enqueue(Checkin, :after_checkin_now, u.id) if u.account_setup? && u.email_for?('checkin_now')
        end
      end
      msg = "Emailed all users on these startups: #{to_email_ids.join(', ')}. Didn't email these startups: #{not_emailed.join(', ')}."
    else
      msg = "All startups have who were active last week completed a checkin today."
    end
    File.open(Rails.root + 'checkin_emailed.txt', 'w') {|f| f.write(msg) }
    return msg
  end

    # Returns hash of {:startup_id => current_checkin}
  def self.current_checkin_for_startups(startups = [])
    return {} if startups.blank?
    if Checkin.in_time_window?(Checkin.default_offset)
      checkins = Checkin.where(:startup_id => startups.map{|s| s.id }).where(['created_at > ?', Checkin.prev_checkin_at(Checkin.default_offset)])
    else # if in before checkin or in the week after, get prev week's checkin start time
      start_time = Checkin.prev_checkin_at(Checkin.default_offset) - 24.hours
      checkins = Checkin.where(:startup_id => startups.map{|s| s.id }).where(['created_at > ? OR completed_at > ?', start_time, start_time])
    end
    checkins.inject({}) do |res, checkin|
      # completed checkins override checkins with just a before
      res[checkin.startup_id] = checkin if res[checkin.startup_id].blank? || checkin.completed?
      res
    end
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

  # Queues up 'before' email to be sent to all active users
  # def self.send_before_checkin_email
  #   users_with_startups = User.where('email IS NOT NULL').where(:startup_id => Startup.select('id').account_complete.map{|s| s.id })

  #   users_with_startups.each do |u|
  #     Resque.enqueue(Checkin, :before, u.id) if u.account_setup? && u.email_for?('docheckin')
  #   end
  # end

  # Queues up 'after' email to be sent to all active users
  # checkin type either :checkin or :checkin_now
  def self.send_checkin_email(checkin_type = :checkin)
    day_of_week = Time.now.wday
    users_with_startups = User.where('email IS NOT NULL').where(:startup_id => Startup.select('id').where(:checkin_day => day_of_week).account_complete.map{|s| s.id })

    users_with_startups.each do |u|
      Resque.enqueue(Checkin, checkin_type, u.id) if u.account_setup? && u.email_for?('docheckin')
    end
  end

  # Mails checkin message
  # Checkin type can be either :checkin or :checkin_now
  def self.perform(checkin_type, user_id)
    if checkin_type.to_sym == :checkin
      UserMailer.after_checkin_reminder(User.find(user_id)).deliver
    elsif checkin_type.to_sym == :checkin_now
      UserMailer.checkin_now(User.find(user_id)).deliver
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
    current_week = Checkin.week_integer_for_time(Checkin.prev_checkin_at(startup.checkin_offset), startup.checkin_offset)
    checkins.each do |c|
      while current_week != c.week
        arr << [false, false]
        # move current week back one week until we hit the next checkin
        current_week = Week.previous(current_week)
      end
      arr << [c.completed?]
      current_week = Week.previous(current_week)
    end
    arr
  end

  def self.num_consecutive_checkins_for_startup(startup)
    history = Checkin.history_for_startup(startup)
    consecutive_checkins = longest_streak = 0
    prev_week = false
    history.each do |completed|
      # If the checkin has a before and after video count it
      if completed
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

  def next_checkin
    Checkin.where(:startup_id => self.startup_id).where(['created_at > ?', self.created_at]).first
  end

  def previous_checkin
    Checkin.where(:startup_id => self.startup_id).where(['created_at < ?', self.created_at]).first
  end

  # Takes youtube urls and converts to our new db-backed format (and uploads to vimeo)
  def convert_to_new_video_format
    return true if self.before_video.present? && self.video.present?
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
    if self.end_video_url.present? && self.video.blank?
      ext_id = Youtube.id_from_url(self.end_video_url)
      y = Youtube.where(:external_id => ext_id).first
      y ||= Youtube.new
      y.external_id = ext_id
      y.user = self.user
      if y.save
        self.video = y
        self.save(:validate => false)
      else
        puts "Couldn't save video: #{y.errors.full_messages}"
      end
    end
    true
  end

  # People who awesomed and commented, minus the team members
  def participants(exclude_ids = [])
    ids = self.awesomes.map{|a| a.user_id }
    ids += self.comments.map{|c| c.user_id }
    ids.uniq!
    ids -= exclude_ids if exclude_ids.present?
    User.where(:id => ids)
  end

  # Cache # of comments
  def update_comments_count
    self.comment_count = self.comments.not_deleted.count
    self.save(:validate => false) # don't require validations in case we're during check-in window with requirements
  end

  def completed?
    !completed_at.blank?
  end

  def submitted?
    !submitted_at.blank?
  end

  def self.video_url_is_unique?(url)
    cs = Checkin.where(:start_video_url => url).or(:end_video_url => url)
    return cs.map{|c| c.id }.delete_if{|id| id == self.id }.count > 0
  end

    # Assigns week for this checkin, ex: 20125 is week 5 of 2012
    # uses created at date, or if not yet saved, current time
  def assign_week
    self.week ||= Checkin.week_integer_for_time(self.created_at || Time.now, self.startup.present? ? self.startup.checkin_offset : Checkin.default_offset)
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

  ####################################
  #
  # METHODS FOR TIME CALCULATION
  #
  #

  # Default offset is a Monday checkin (due at end of day on Monday)
  def self.default_offset
    # [ offset from beginning of week, duration of time window ]
    [1.day, 24.hours]
  end

  def self.pct_complete_week(offset)
    nc = Checkin.next_checkin_at(offset)
    return 100 if nc < Time.now
    100 - (((nc - Time.now) / (nc - (nc - 1.week))) * 100).round
  end

  # Returns time of next checkin deadline
  def self.next_checkin_at(offset)
    t = Time.now
    Checkin.next_window_for(offset).last
  end

  # Returns time when prev checkin was over
  def self.prev_checkin_at(offset)
    self.next_checkin_at(offset) - 1.week
  end

  # Pass in a timestamp and this will return the start (default midnight on Tue) of that checkin's week
  def self.week_start_for_time(time, offset)
    # reset to tuesday
    week_start = time.beginning_of_week + offset.first + offset.last
    if time < week_start
      # We're in the offset time, so use last week
      return week_start - 7.days
    else
      return week_start
    end
  end

  # Pass in a timestamp and this will return the current week description for that timestamp
  # ex: Jul 5 to Jul 12
  def self.week_for_time(time, offset)
    # reset to tuesday
    beginning_of_week = Checkin.week_start_for_time(time, offset)
    Week.for_time(beginning_of_week)
  end

  # Given a time, returns its corresponding integer (ex: 201214)
  def self.week_integer_for_time(time, offset)
    Week.integer_for_time(Checkin.week_start_for_time(time, offset))
  end

  # Current week for the checkin
  def self.current_week(offset)
    Week.integer_for_time(Time.now, offset)
  end

      # Returns true if time given is in the time window. If no time given, defaults to now
  def self.in_time_window?(offset, time = nil)
    time ||= Time.now
    next_window = Checkin.next_window_for(offset)
    return true if time > next_window.first && time < next_window.last
    false
  end

    # Returns array of [start_time, end_time] for this type
  def self.next_window_for(offset, dont_skip_if_in_window = false)
    t = Time.now
    beginning_of_week = t.beginning_of_week
    window_start = beginning_of_week + offset.first
    # We're after the beginning of this time window, so add a week unless we're suppressing that
    window_start += 1.week if (t > window_start + offset.last) && !dont_skip_if_in_window
    [window_start, window_start + offset.last]
  end

  # Returns label string - ex: November 14 to November 20th
  def time_label
    Checkin.week_for_time(self.created_at || Time.now, self.startup.present? ? self.startup.checkin_offset : Checkin.default_offset)
  end

  # Returns time window for this checkin
  def time_window
    Week.window_for_integer(self.week, self.startup.checkin_offset)
  end

  protected

  def next_weeks_goal_is_present
    if self.previous_step >= 3
      goal = self.next_week_goal
      goal = self.next_checkin.goal if goal.blank? && self.next_checkin.present?
      self.errors.add(:goal, "can't be blank") if goal.blank?
      return false
    end
    true
  end

  def create_next_week_checkin
    return true if self.next_week_goal.blank?
    return true if self.next_checkin.present?
    self.assign_week if self.week.blank?
    c = Checkin.new
    c.startup_id = self.startup_id
    c.user_id = self.user_id
    c.week = Checkin.week_integer_for_time(Checkin.next_checkin_at(c.startup.checkin_offset), c.startup.checkin_offset)
    c.goal = self.next_week_goal
    c.save(:validate => false) # ignore errors for now
  end

  def set_previous_step
    self.previous_step = self.current_step
  end

  def reset_startup_checkin_cache
    self.startup.reset_current_checkin_cache
  end

  def add_completed_at_time
    self.completed_at = Time.now if !self.completed? && self.errors.blank? && self.current_step == 4
    true
  end

  def measurement_is_present_if_launched
    if self.startup.present? && self.startup.launched? && self.previous_step > 0
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
