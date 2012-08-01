class Screenshot < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user

  attr_accessible :user_id, :startup_id, :image, :image_cache, :remove_image

  validates_presence_of :image

  mount_uploader :image, ScreenshotUploader # carrierwave file uploads

  scope :ordered, order('position ASC')
end
