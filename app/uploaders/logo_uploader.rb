require 'base_uploader'

# Startup logo
class LogoUploader < BaseUploader
   # Add another version

  version :square do
    process :resize_to_fill => [200, 200]
    process :quality => 70
  end
end