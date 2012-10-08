require 'base_uploader'

# Startup logo
class LogoUploader < BaseUploader
   # Add any additional versions or post-processing

   version :lg_square do
    process :resize_to_fill => [400, 400]
    process :quality => 70
  end
end