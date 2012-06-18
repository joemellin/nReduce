class Checkin < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user # the user logged in who created check-in
  has_many :comments
  has_many :awesomes, :as => :awsm

  attr_accessible :start_focus, :start_why, :start_video_url, :end_video_url, :end_comments, :startup_id, :start_comments

  after_validation :check_submitted_completed_times
  before_save :notify_user

  validates_presence_of :startup_id
  validates_presence_of :start_focus, :message => "can't be blank"
  validates_presence_of :start_video_url, :message => "can't be blank"
  validates_presence_of :end_video_url, :message => "can't be blank", :if =>  Proc.new {|checkin| checkin.completed? }
  validate :check_video_urls_are_valid

  scope :ordered, order('created_at DESC')
  scope :completed, where('completed_at IS NOT NULL')

  @queue = :checkin_message

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

    # Returns Time of next before checkin
  def self.next_before_checkin
    t = Time.now
    # Are we in Mon or tue? - if so next before checkin is this week
    if t.monday? or (t.tuesday? and t.hour < 16)
      return t.beginning_of_week + 1.day + 16.hours
    else
      # Otherwise it's next week
      return t.beginning_of_week + 1.week + 1.day + 16.hours
    end
  end

   # Returns Time of next after checkin
  def self.next_after_checkin
    t = Time.now
    # Are we in Mon or tue? - if so next before checkin is this week
    if t.monday? or t.tuesday? or (t.wednesday? and t.hour < 16)
      t.beginning_of_week + 2.days + 16.hours
    else
      # Otherwise it's next week
      t.beginning_of_week + 1.week + 2.days + 16.hours
    end
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

  # Pass in a timestamp and this will return the current week description for that timestamp
  # ex: Jul 5 to Jul 12
  def self.week_for_time(time)
    # reset to tuesday
    if time.sunday? or time.monday? or (time.tuesday? and time.hour < 16)
      time = time.beginning_of_week - 5.days
    else
      time = time.beginning_of_day - time.days_to_week_start.days + 2.days
    end
    time += 16.hours # set it at 4pm
    week_end = time + 6.days
    "#{time.strftime('%b %-d')}-#{week_end.strftime('%b %-d')}"
  end

  # Queues up 'before' email to be sent to all active users
  def self.send_before_checkin_email
    users_with_startups = User.select('id, email, settings').where('email IS NOT NULL').where(:startup_id => Startup.select('id').onboarded.map{|s| s.id })

    users_with_startups.each do |u|
      Resque.enqueue(Checkin, :before, u.id) if u.email_for?('docheckin')
    end
  end

  # Queues up 'after' email to be sent to all active users
  def self.send_after_checkin_email
    users_with_startups = User.select('id, email, settings').where('email IS NOT NULL').where(:startup_id => Startup.select('id').onboarded.map{|s| s.id })

    users_with_startups.each do |u|
      Resque.enqueue(Checkin, :after, u.id) if u.email_for?('docheckin')
    end
  end

  # Mails checkin message
  # Checkin type can be either :before, :after
  def self.perform(checkin_type, user_id)
    if checkin_type == :before
      UserMailer.before_checkin_reminder(User.find(user_id)).deliver
    elsif checkin_type == :after
      UserMailer.after_checkin_reminder(User.find(user_id)).deliver
    end
  end

  def time_label
    Checkin.week_for_time(self.created_at || Time.now)
  end

  def submitted?
    !submitted_at.blank?
  end

  def completed?
    !completed_at.blank?
  end

  def self.video_url_is_unique?(url)
    cs = Checkin.where(:start_video_url => url).or(:end_video_url => url)
    return cs.map{|c| c.id }.delete_if{|id| id == self.id }.count > 0
  end

  protected

  def check_video_urls_are_valid
    err = false
    if !start_video_url.blank? and !Youtube.valid_url?(start_video_url)
      self.errors.add(:start_video_url, 'invalid Youtube URL')
      err = true
    end
    if !end_video_url.blank? and !Youtube.valid_url?(end_video_url)
      self.errors.add(:end_video_url, 'invalid Youtube URL')
      err = true
    end
    err
  end

  def check_submitted_completed_times
    if self.errors.blank?
      self.submitted_at = Time.now if !self.submitted? and !start_focus.blank? and !start_video_url.blank?
      self.completed_at = Time.now if self.submitted? and !self.completed? and !end_video_url.blank?
    end
    true
  end

  def notify_user
    # only notify first time it changes state to completed
    Notification.create_for_new_checkin(self) if self.completed? and self.completed_at_changed?
  end
end
