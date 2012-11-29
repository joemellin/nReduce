class AddNextWeekGoalToCheckin < ActiveRecord::Migration
  def change
    add_column :checkins, :next_week_goal, :string
  end
end
