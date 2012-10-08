class AddAccomplishedToCheckin < ActiveRecord::Migration
  def change
    add_column :checkins, :accomplished, :boolean
  end
end
