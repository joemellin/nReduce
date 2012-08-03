require 'base_uploader'

# Product screenshot
class ScreenshotUploader < BaseUploader
  # Add any additional versions or post-processing

  version :large do
    process :resize_to_fit => [1024, 768]
    process :quality => 70
  end
end