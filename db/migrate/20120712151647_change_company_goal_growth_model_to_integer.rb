class ChangeCompanyGoalGrowthModelToInteger < ActiveRecord::Migration
  def up
    %w(growth_model company_goal stage).each do |col|
      connection.execute(%{
         alter table startups
         alter column #{col}
         type integer using cast(#{col} as integer)
       })
    end

    add_column :startups, :pitch_video_url, :string
  end

  def down
    change_column :startups, :growth_model, :string
    change_column :startups, :company_goal, :string
    change_column :startups, :stage, :string
    remove_column :startups, :pitch_video_url, :string
  end
end
