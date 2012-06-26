class AddStatsToUserAndStartup < ActiveRecord::Migration
  def change
    add_column :users, :rating, :float
    add_column :startups, :rating, :float
  end
end
