class CreateMeetings < ActiveRecord::Migration
  def change
    create_table :meetings do |t|
      t.string :location_name, :venue_name, :venue_url, :description, :venue_address
      t.integer :start_time, :default => 1830
      t.integer :day_of_week, :default => 2
      t.float :lat, :lng
      t.references :organizer
      t.timestamps
    end
  end
end
