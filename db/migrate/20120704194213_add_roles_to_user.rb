class AddRolesToUser < ActiveRecord::Migration
  def up
    add_column :users, :roles, :integer, :length => 15
    add_index :users, :startup_id
    add_index :users, :roles
    User.mentor.each do |u|
      u.roles << :mentor
      u.save
    end
  end

  def down
    remove_column :users, :roles
    remove_index :users, :startup_id
    remove_index :users, :roles
  end
end
