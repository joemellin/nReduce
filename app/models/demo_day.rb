class DemoDay < ActiveRecord::Base
  attr_accessible :name, :day, :description, :startup_ids

  serialize :startup_ids

  def startups
    return [] if self.startup_ids.blank?
    Startup.find(self.startup_ids)
  end
end
