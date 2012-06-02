class CreateStartups < ActiveRecord::Migration
  def change
    create_table :startups do |t|
      t.string :name, :team_members, :location_name, :product_url, :one_liner
      t.boolean :active, :default => true
      t.references :user, :location, :batch
      t.timestamps
    end

    add_index :startups, :location_id
    add_index :startups, :active
  end
end
