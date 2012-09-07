class AddStartuptoVideos < ActiveRecord::Migration
  def change
    add_column :videos, :startup_id, :integer
  end
end
