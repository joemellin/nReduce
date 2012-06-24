module CarrierWave
  module RMagick
    # Reduce quality of image to this percentage, eg: 70
    def quality(percentage)
      manipulate! do |img|
        img.write(current_path){ self.quality = percentage }
        img = yield(img) if block_given?
        img
      end
    end

    # Strips out all embedded information from the image
    def strip
      manipulate! do |img|
        img.strip!
        img = yield(img) if block_given?
        img
      end
    end

     # Rotates the image based on the EXIF Orientation
    def fix_exif_rotation
      manipulate! do |img|
        img.auto_orient!
        img = yield(img) if block_given?
        img
      end
    end

    # Sharpens the image
    def sharpen
      manipulate! do |img|
        img.sharpen(0) # selets a suitable radius
        img = yield(img) if block_given?
        img
      end
    end
  end
end