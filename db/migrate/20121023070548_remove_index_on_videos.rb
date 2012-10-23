class RemoveIndexOnVideos < ActiveRecord::Migration
  def up
    remove_index :videos, [:external_id, :type]
    add_index :videos, [:external_id, :type]
  end

  def down
    remove_index :videos, [:external_id, :type]
    add_index :videos, [:external_id, :type], :unique => true
  end
end
