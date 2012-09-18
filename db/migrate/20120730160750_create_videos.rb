class CreateVideos < ActiveRecord::Migration
  def change
    create_table :videos do |t|
      t.integer :user_id
      t.string :external_id
      t.integer :video_type
      t.string :file_url
      t.text :callback_result
      t.integer :vimeo_id
      t.timestamps
    end
  end
end
