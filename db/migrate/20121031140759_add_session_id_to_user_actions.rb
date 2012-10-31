class AddSessionIdToUserActions < ActiveRecord::Migration
  def change
    add_column :user_actions, :session_id, :string
  end
end
