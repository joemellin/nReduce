class AddWeekToCheckin < ActiveRecord::Migration
  def change
    add_column :checkins, :week, :integer, :length => 6

    Checkin.all.each do |c|
      c.assign_week
      c.save(:validate => false)
    end
  end
end
