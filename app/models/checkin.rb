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

    # Returns true if in the time window where startups can do 'before' check-in
  def self.in_before_time_window?
    # tues from 4pm - wed 4pm
    t = Time.now
    return true if (t.tuesday? and t.hour > 16) or (t.thursday? and t.hour < 16)
    false
  end

    # Returns true if in the time window where startups can do 'after' check-in
  def self.in_after_time_window?
    # monday from 4pm - tue 4pm
    t = Time.now
    return true if (t.monday? and t.hour > 16) or (t.tuesday? and t.hour < 16)
    false
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
    "#{time.strftime('%b %-d')} to #{week_end.strftime('%b %-d')}"
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
    Notification.create_for_new_checkin(self) if checkin.completed? and checkin.completed_at_changed?
  end
end
