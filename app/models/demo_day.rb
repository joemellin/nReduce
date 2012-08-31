class DemoDay < ActiveRecord::Base
  attr_accessible :name, :day, :description, :startup_ids

  serialize :startup_ids
  serialize :attendee_ids

  # Returns next demo day or current (current is demo day on this day)
  def self.next_or_current
    DemoDay.where(['day >= ?', Date.today]).order('day ASC').first
  end

  def startups
    return [] if self.startup_ids.blank?
    Startup.find(self.startup_ids)
  end

  def starts_at
    return Time.now - 5.minutes
    Time.parse("#{self.day} 11:00:00 -0700")
  end

  def ends_at
    Time.parse("#{self.day} 13:00:00 -0700")
  end

  # Returns true if it's currently the time window for this demo day
  def in_time_window?
    self.starts_at <= Time.now && self.ends_at >= Time.now
  end

  # Returns next demo day in chronological order
  def next_demo_day
    DemoDay.where(['day > ?', self.day]).order('day ASC').first
  end

  def attendees
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

    # Tweet from supporter's account
    unless dont_tweet
      tw = user.twitter_client
      tw.update("I'm checking out some awesome companies in the nReduce Demo Day! #nReduce") if Rails.env.production? && tw.present?
    end

    save
  end
end
