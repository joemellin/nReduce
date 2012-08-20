class Rating < ActiveRecord::Base
  belongs_to :investor, :class_name => 'User'
  belongs_to :startup

  attr_accessible :explanation, :feedback, :interested, :investor_id, :startup_id, :value

  FEEDBACK_OPTIONS = [:team, :idea, :traction, :market]

  bitmask :feedback, :as => Rating::FEEDBACK_OPTIONS

  validates_presence_of :startup_id
  validates_presence_of :investor_id
  validates_presence_of :value
  #validates_length_of :explanation, :minimum => 50
  validate :relationship_exists
  validate :investor_can_connect

  before_create :change_suggested_relationship_state

  def self.labels
    { 1 => 'Never',
      2 => '6 months',
      3 => '3 months',
      4 => '1 month',
      5 => 'Today',
    }
  end

  # Finds the relationship that exists between the startup and investor involved in this rating
  def startup_relationship
    Relationship.between(self.investor, self.startup)
  end

  protected

  def investor_can_connect
    if self.interested? # only check if they want to connect
      unless self.investor.can_connect_with_startups?
        self.errors.add(:startup_id, 'you have reached your limit - please upgrade your account to connect to more startups')
        return false
      end
    end
    true
  end

  def relationship_exists
    if self.new_record?
      rel = self.startup_relationship
      if rel.blank? || (!rel.blank? and !rel.suggested?)
        self.errors.add(:startup_id, "has already been rated by you.")
        return false
      end
    end
    true
  end

  # Sets suggested relationship to pending if interested, or passed if they pass
  def change_suggested_relationship_state
    if self.new_record?
      rel = self.startup_relationship
      if self.interested?
        rel.approve! # turns it to pending state
      else
        rel.reject_or_pass! # sets it as passed
      end
    end
    true
  end
end
