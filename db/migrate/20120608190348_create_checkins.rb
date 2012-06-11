class CreateCheckins < ActiveRecord::Migration
  def change
    create_table :checkins do |t|
      t.string :start_focus, :start_why, :start_video_url, :end_video_url
      t.text :end_comments
      t.datetime :submitted_at, :completed_at
      t.references :startup, :user
      t.timestamps
    end

    add_index :checkins, [:startup_id, :created_at]
  end
end
