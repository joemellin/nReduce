class AddHipchatToUser < ActiveRecord::Migration
  def change
    add_column :users, :hipchat_username, :string
    add_column :users, :hipchat_password, :string
  end
end
