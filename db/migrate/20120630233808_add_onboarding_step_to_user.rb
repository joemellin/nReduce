class AddOnboardingStepToUser < ActiveRecord::Migration
  def change
    add_column :users, :onboarding_step, :integer, :default => 1, :length => 2
    add_column :users, :intro_video_url, :string
  end
end
