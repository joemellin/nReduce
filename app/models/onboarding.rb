class Onboarding
  def self.onboarding_types
    [:startup, :mentor, :investor]
  end

  # total number of possible onboarding steps
  def self.num_onboarding_steps
    10
  end

  # depending on the onboarding type some pages are skipped
  def self.skip_onboarding_step?(type, step)
    # ex: return true if type == :startup and [4.5].include?(step)
    false
  end
end