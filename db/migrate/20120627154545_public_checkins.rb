class PublicCheckins < ActiveRecord::Migration
  def change
  	add_column :startups, :checkins_public, :boolean, :default => false
  end
end
