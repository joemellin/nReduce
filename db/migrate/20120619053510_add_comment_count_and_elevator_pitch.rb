class AddCommentCountAndElevatorPitch < ActiveRecord::Migration
  def change
    add_column :checkins, :comment_count, :integer, :default => 0
    add_column :startups, :elevator_pitch, :text
  end
end
