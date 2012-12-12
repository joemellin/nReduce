class AddSeenMessageToUSer < ActiveRecord::Migration
  def change
    add_column :users, :shem, :boolean, :default => false
  end
end
