class ChangeCompanyGoalGrowthModelToInteger < ActiveRecord::Migration
  def up
    change_column :startups, :growth_model, :integer, :length => 2
    change_column :startups, :company_goal, :integer, :length => 2
    change_column :startups, :stage, :integer, :length => 2
    add_column :startups, :pitch_video_url, :string
  end

  def down
    change_column :startups, :growth_model, :string
    change_column :startups, :company_goal, :string
    change_column :startups, :stage, :string
    remove_column :startups, :pitch_video_url, :string
  end
end
