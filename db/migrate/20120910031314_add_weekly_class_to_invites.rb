class AddWeeklyClassToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :weekly_class_id, :integer
  end
end
