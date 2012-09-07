class AddVideoIdsToModels < ActiveRecord::Migration
  def change
    add_column :checkins, :before_video_id, :integer
    add_column :checkins, :after_video_id, :integer
    add_column :startups, :intro_video_id, :integer
    add_column :startups, :pitch_video_id, :integer
    add_column :users, :intro_video_id, :integer

    add_column :videos, :title, :string
  end
end
