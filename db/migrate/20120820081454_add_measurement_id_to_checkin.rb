class AddMeasurementIdToCheckin < ActiveRecord::Migration
  def change
    add_column :checkins, :measurement_id, :integer
  end
end
