class AddWeekToStartup < ActiveRecord::Migration
  def change
    add_column :startups, :week, :integer
    add_index :startups, :week
  end
end
