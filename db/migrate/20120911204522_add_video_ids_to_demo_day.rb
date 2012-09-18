class AddVideoIdsToDemoDay < ActiveRecord::Migration
  def change
    add_column :demo_days, :video_ids, :text
  end
end
