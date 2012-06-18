class AddUnreadNcToUser < ActiveRecord::Migration
  def change
    add_column :users, :unread_nc, :integer, :default => 0
  end
end
