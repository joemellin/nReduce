class Onboarding
  def self.steps
    [:your_teams, :checkins, :give_feedback, :find_teams]
  end

  # total number of possible onboarding steps
  def self.num_onboarding_steps
    Onboarding.steps.size
  end
end