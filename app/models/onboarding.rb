class Onboarding
  def self.steps
    [:welcome, :weekly_schedule, :connect, :feedback, :your_group, :watercooler]
  end

  # total number of possible onboarding steps
  def self.num_onboarding_steps
    Onboarding.steps.size
  end
end