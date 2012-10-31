class CreateStartups < ActiveRecord::Migration
  def change
    create_table :startups do |t|
      t.string :name, :location_name, :product_url, :one_liner, :phone, :website_url, :stage, :growth_model, :company_goal, :intro_video_url
      t.integer :onboarding_step, :team_size, :default => 1
      t.boolean :active, :default => false
      t.boolean :public, :default => true
      t.datetime :launched_at
      t.has_attached_file :logo
      t.references :main_contact, :meeting
      t.timestamps
    end

    add_index :startups, :public
  end
end
