class AddIndexOffsetToDemoDays < ActiveRecord::Migration
  def change
    add_column :demo_days, :index_offset, :integer, :default => 0
  end
end
