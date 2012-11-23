class ModifyForNewCheckinFormat < ActiveRecord::Migration
  def up
    add_column :startups, :time_zone, :string
    add_column :startups, :checkin_day, :integer, :default => 1
    rename_column :checkins, :after_video_id, :after_video
    rename_column :checkins, :end_comments, :notes
    rename_column :checkins, :start_focus, :goal
  end

  def down
    remove_column :startups, :time_zone
    remove_column :startups, :checkin_day
    rename_column :checkins, :after_video, :after_video_id
    rename_column :checkins, :notes, :end_comments
    rename_column :checkins, :goal, :start_focus
  end
end
