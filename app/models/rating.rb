class Rating < ActiveRecord::Base
  belongs_to :investor, :class_name => 'User'
  belongs_to :startup

  attr_accessible :explanation, :feedback, :interested, :investor_id, :startup_id, :contact_in, :weakest_element

  FEEDBACK_OPTIONS = [:team, :idea, :traction, :market]

  bitmask :feedback, :as => Rating::FEEDBACK_OPTIONS

  validates_presence_of :startup_id
  validates_presence_of :investor_id
  validates_presence_of :contact_in
  validates_presence_of :weakest_element
  validate :relationship_exists
  validate :investor_can_connect

  before_create :change_suggested_relationship_state

  def self.contact_in_labels
    { 1 => ['Not a fit', "Don't show me this startup again"],
      2 => ['6 months', 'Show me again in 6 months and I might be interested'],
      3 => ['3 months', 'Show me again in 3 months and I might be interested'],
      4 => ['1 month', 'Show me again in 1 month and I might be interested'],
      5 => ['Now', 'Please introduce me today']
    }
  end

  def self.weakest_element_labels
    { 1 => 'Team',
      2 => 'Market',
      3 => 'Traction',
      4 => 'Product',
      5 => 'Other',
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
