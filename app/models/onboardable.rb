module Onboardable
  # Add to classes that go through a multi-step onboarding process
  
  def self.included(base)
    # Adding relationships here so it doesn't complain that active_record isn't avail
    base.class_eval do
      scope :onboarded, lambda {|obj| where(:onboarding_step => obj.num_onboarding_steps) }
    end
  end

  def onboarding_step_increment!
    self.update_attribute('onboarding_step', self.onboarding_step + 1) unless self.onboarding_complete?
  end

    # Onboarding steps - hardcoded here at 9
  def onboarding_complete?
    self.onboarding_step == self.num_onboarding_steps
  end

  def num_onboarding_steps
    9
  end
end