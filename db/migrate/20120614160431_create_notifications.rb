class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :message, :action
      t.references :attachable, :polymorphic => true
      t.references :user
      t.boolean :emailed, :default => false
      t.datetime :read_at, :created_at
    end

    add_index :notifications, [:user_id, :read_at]
    add_column :users, :settings, :text

    # Add default settings for all users
    User.all.each{|u| u.settings = User.default_settings; u.save(:validate => false) }
  end
end
