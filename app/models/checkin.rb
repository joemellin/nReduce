class Checkin < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user # the user logged in who created check-in
  has_many :comments

  attr_accessible :start_focus, :start_why, :start_video_url, :end_video_url, :end_comments, :startup_id

  after_validation :check_submitted_completed_times

  validates_presence_of :startup_id
  validates_presence_of :start_focus, :message => "can't be blank"
  validates_presence_of :start_video_url, :message => "can't be blank"
  validates_presence_of :end_video_url, :message => "can't be blank", :if =>  Proc.new {|checkin| checkin.completed? }
  validate :check_video_urls_are_valid

  scope :ordered, order('created_at DESC')
  #scope :current, lambda { t = Time.now; t = t.beginning_of_day - 1.day if (t.monday? and t.hour < 16); where(['created_at > ?', t]) }
  scope :current, where(['created_at > ?', Time.now - 7.days])

    # Returns true if in the time window where startups can do 'before' check-in
  def self.in_before_time_window?
    # tues from 4pm - wed 4pm
    t = Time.now
    return true if (t.tuesday? and t.hour > 16) or (t.wednesday? and t.hour < 16)
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
    if time.sunday? or (time.monday? and time.hour < 16)
      time = time.beginning_of_week - 5.days
    else
      time = time.begining_of_day + (time.days_to_week_start.days - 5.days)
    end
    time += 16.hours # set it at 4pm
    week_end = time + 7.days
    "#{time.strfime('%b %-d')} to #{week_end.strfime('%b %-d')}"
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
end
