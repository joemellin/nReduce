class DemoDay < ActiveRecord::Base
  attr_accessible :name, :day, :description, :startup_ids

  serialize :startup_ids

  def startups
    return [] if self.startup_ids.blank?
    Startup.find(self.startup_ids)
  end

  def starts_at
    Time.parse("#{self.day} 11:00:00 -0700")
  end

  def ends_at
    Time.parse("#{self.day} 13:00:00 -0700")
  end

  # Returns true if it's currently the time window for this demo day
  def in_time_window?
    self.starts_at <= Time.now && self.ends_at >= Time.now
  end
end
