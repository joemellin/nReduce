class Video < ActiveRecord::Base
  belongs_to :checkin   # before/after video
  belongs_to :user      # profile video
  belongs_to :startup   # team video, pitch video

  attr_accessible :callback_result, :external_id, :file_url, :user_id, :video_type, :vimeo_id
end
