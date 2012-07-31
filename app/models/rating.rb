class Rating < ActiveRecord::Base
  belongs_to :investor, :class_name => 'User'
  belongs_to :startup

  attr_accessible :explanation, :feedback, :interested, :investor_id, :startup_id

  FEEDBACK_OPTIONS = [:team, :idea, :traction, :market]

  bitmask :feedback, :as => Rating::FEEDBACK_OPTIONS

  before_validation :change_suggested_relationship_state

  validates_presence_of :startup_id
  validates_presence_of :investor_id
  validates_presence_of :explanation
  validate :investor_can_connect

  # Finds the relationship that exists between the startup and investor involved in this rating
  def startup_relationship
    Relationship.between(self.investor, self.startup)
  end

  protected

  def investor_can_connect
    if self.interested? # only check if they want to connect
      if self.investor.can_connect_with_startups?
        true
      else
        self.errors.add(:startup_id, 'you have reached your limit - please upgrade your account to connect to more startups')
        false
      end
    else
      true
    end
  end

  # Sets suggested relationship to pending if interested, or passed if they pass
  def change_suggested_relationship_state
    if self.new_record?
      rel = self.startup_relationship
      if rel.blank?
        self.errors.add(:startup_id, "rating can't be given to this startup.")
      elsif rel
        if rel.suggested? # only approve/pass if it's a suggested relationship
          if self.interested?
            rel.approve!
          else
            rel.reject_or_pass!
          end
        else
          self.errors.add(:startup_id, "rating can't be given to this startup.")
        end
      end
    end
    true
  end
end
