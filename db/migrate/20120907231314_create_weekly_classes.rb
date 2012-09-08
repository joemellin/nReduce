class CreateWeeklyClasses < ActiveRecord::Migration
  def change
    create_table :weekly_classes do |t|
      t.integer :week, :num_startups, :num_users, :num_countries, :num_industries
      t.text :user_ids, :clusters
      t.timestamps
    end

    add_index :weekly_classes, :week, :unique => true

    # Create Weekly classes for past users
    WeeklyClass.populate_for_past_weeks
  end
end
