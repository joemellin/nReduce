class AddAbTestToUserActions < ActiveRecord::Migration
  def change
    add_column :user_actions, :ab_test_id, :integer
    add_column :user_actions, :ab_test_version, :string
  end
end
