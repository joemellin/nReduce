class CreateStartups < ActiveRecord::Migration
  def change
    create_table :startups do |t|
      t.string :name, :team_members, :location_name, :product_url, :one_liner, :phone, :team_size, :website_url, :industry, :stage, :growth_model, :company_goal, :intro_video_url
      t.integer :onboarding_step, :default => 1
      t.boolean :active, :public, :default => true
      t.has_attached_file :logo
      t.references :user, :venue
      t.timestamps
    end

    add_index :startups, :active
  end
end
