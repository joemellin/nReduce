class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :name, :venue_name, :venue_url, :venue_description
      t.integer :order, :default => 100000
      t.timestamps
    end

    add_index :locations, :order
  end
end
