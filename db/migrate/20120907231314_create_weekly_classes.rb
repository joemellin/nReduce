class CreateWeeklyClasses < ActiveRecord::Migration
  def change
    add_column :users, :weekly_class_id, :integer
    add_column :users, :country, :string
    add_index :users, :weekly_class_id

    create_table :weekly_classes do |t|
      t.integer :week
      t.integer :num_startups, :num_users, :num_countries, :num_industries, :default => 0
      t.text :clusters
      t.timestamps
    end

    add_index :weekly_classes, :week, :unique => true
  end
end
