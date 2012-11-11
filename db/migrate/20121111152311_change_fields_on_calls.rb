class ChangeFieldsOnCalls < ActiveRecord::Migration
  def up
    remove_column :calls, :from_sid
    rename_column :calls, :to_sid, :sid
  end

  def down
    add_column :calls, :from_sid, :string
    rename_column :calls, :sid, :to_sid
  end
end
