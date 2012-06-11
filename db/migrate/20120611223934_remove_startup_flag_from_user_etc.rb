class RemoveStartupFlagFromUserEtc < ActiveRecord::Migration
  def up
    remove_column :users, :startup
    remove_column :startups, :product_url
    rename_column :startups, :location_name, :location
  end

  def down
    add_column :users, :startup, :boolean
    add_column :startups, :product_url, :string
    rename_column :startups, :location, :location_name
  end
end
