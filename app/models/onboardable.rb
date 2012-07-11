module Onboardable
  # Add to classes that go through a multi-step onboarding process

  def self.included(base)
    # Adding relationships here so it doesn't complain that active_record isn't avail
    base.class_eval do
      scope :onboarded, lambda { where(:onboarding_step => self.num_onboarding_steps) }
    
      def self.num_onboarding_steps
        self.new.num_onboarding_steps
      end
    end
  end

  def onboarding_step_increment!
    next_step = self.onboarding_step + 1
    # Logic is added for people in certain conditions to skip the next step
    while(self.skip_onboarding_step?(next_step))
      next_step += 1
    end
    self.update_attribute('onboarding_step', next_step) unless self.onboarding_complete?
  end

    # Onboarding steps - hardcoded here at 9
  def onboarding_complete?
    self.onboarding_step >= self.num_onboarding_steps
  end

  def num_onboarding_steps
    9
  end

  def skip_onboarding_step?(step)
    false
  end
end