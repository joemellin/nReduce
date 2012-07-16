class CleanupUserTable < ActiveRecord::Migration
  def up
    add_column :users, :email_on, :integer

    User.all.each do |u|
      u.roles << :entrepreneur unless u.startup_id.blank?
      u.email_on = u.settings['email_on'] unless u.settings.blank?
      u.onboarded << :mentor if u.onboarding_complete?
      u.save
    end

    remove_column :users, :mentor
    remove_column :users, :investor
    remove_column :users, :onboarding_step
    remove_column :users, :settings

    # Add columns for setup
    add_column :users, :setup, :integer
    add_column :startups, :setup, :integer
  end

  def down
    add_column :users, :mentor, :boolean
    add_column :users, :investor, :boolean
    add_column :users, :onboarding_step, :integer, :length => 11
    add_column :users, :settings, :string

    remove_column :users, :setup
    remove_column :startups, :setup
  end
end
