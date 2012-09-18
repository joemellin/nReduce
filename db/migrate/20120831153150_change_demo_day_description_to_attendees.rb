class ChangeDemoDayDescriptionToAttendees < ActiveRecord::Migration
  def up
    rename_column :demo_days, :description, :attendee_ids
  end

  def down
    rename_column :demo_days, :attendee_ids, :description
  end
end
