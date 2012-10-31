class AddEncodeCheckToVideos < ActiveRecord::Migration
  def change
    add_column :videos, :ecc, :integer, :default => 0
  end
end
