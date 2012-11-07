class DemoDay < ActiveRecord::Base
  attr_accessible :name, :day, :description, :startup_ids

  serialize :startup_ids
  serialize :attendee_ids
  serialize :video_ids

  scope :ordered, order('day DESC')

  # Returns next demo day or current (current is demo day on this day)
  def self.next_or_current
    DemoDay.where(['day >= ?', Date.today]).order('day ASC').first
  end

  def self.tweet_content
    "I'm checking out some awesome companies in the #{Settings.demo_day.hashtag}! http://nreduce.com/d"
  end

  # Add index offset so that we can use same url for different demo days -- /d/:startup_id
  # def index_of(startup_or_id)
  #   return nil if self.startup_ids.blank?
  #   id = startup_or_id.is_a?(Startup) ? startup_or_id.id : startup_or_id.to_i
  #   index = self.startup_ids.index(id)
  #   index += self.index_offset if index.present?
  #   index
  # end

  def to_param
    "#{self.id}-#{self.day.strftime("%B-%Y")}"
  end

  def includes_startup?(startup)
    self.index_of(startup) != nil
  end

  def index_of(startup)
    return nil if self.startup_ids.blank?
    self.startup_ids.index(startup.id) + self.index_offset
  end

  def startup_for_index(index)
    self.startup_ids[index.to_i - self.index_offset]
  end

  def video_for_startup(startup)
    i = self.index_of(startup)
    return Video.find(self.video_ids[i]) if self.video_ids.present? && self.video_ids[i].present?
    return nil
  end

  def hide_checkins?(startup)
    return true if [742, 585].include?(startup.id)
    false
  end

  def startups
    return [] if self.startup_ids.blank?
    Startup.find(self.startup_ids)
  end

  def starts_at
    return Time.now - 5.minutes if Rails.env.development?
    Time.parse("#{self.day} 11:00:00 -0800")
  end

  def ends_at
    return Time.now + 10.minutes if Rails.env.development?
    Time.parse("#{self.day} 12:00:00 -0800")
  end

  # Returns true if it's currently the time window for this demo day
  def in_time_window?
    self.starts_at <= Time.now && self.ends_at >= Time.now
  end

  def in_the_past?
    self.ends_at <= Time.now
  end

  def in_the_future?
    self.starts_at >= Time.now
  end

  # Returns next demo day in chronological order
  def next_demo_day
    DemoDay.where(['day > ?', self.day]).order('day ASC').first
  end

  def attendees
    return [] if self.attendee_ids.blank?
    User.find(self.attendee_ids)
  end

  def is_attendee?(user)
    return true if self.attendee_ids.include?(user.id) if self.attendee_ids.present?
    return false
  end

  # Add attendee and tweet that they attended
  
  def add_attendee!(user, dont_tweet = false)
    # Return true if already a supporter
    return true if self.is_attendee?(user)
    self.attendee_ids ||= []
    # Add supporter id
    self.attendee_ids << user.id

    # Tweet from supporter's account - no longer doing this now
    # unless dont_tweet
    #   tw = user.twitter_client
    #   tw.update(DemoDay.tweet_content) if Rails.env.production? && tw.present?
    # end

    save
  end
end
