class Video < ActiveRecord::Base
  attr_accessible :callback_result, :external_id, :file_url, :user_id, :video_type, :vimeo_id
end
