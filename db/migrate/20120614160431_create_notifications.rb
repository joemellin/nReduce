class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :message
      t.references :attachable, :polymorphic => true
      t.references :user
      t.boolean :emailed, :default => false
      t.datetime :read_at, :created_at
    end

    add_index :notifications, [:user_id, :read_at]
    add_column :users, :notification_prefs, :string
  end
end
