# encoding: utf-8

# Carrierwave wiki: https://github.com/jnicklas/carrierwave/wiki

class BaseUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick # See /initialiers/carrierwave.rb for method additions
  include CarrierWave::MimeTypes

  process :set_content_type

  # Include the Sprockets helpers for Rails 3.1+ asset pipeline compatibility:
  include Sprockets::Helpers::RailsHelper
  include Sprockets::Helpers::IsolatedHelper

  # Choose what kind of storage to use for this uploader:
  storage (Rails.env.production? || Rails.env.development?) ? :fog : :file

  #
  # IMAGE PROCESSING AND SIZES
  #

  # Rotate files if they aren't
  process :fix_exif_rotation
  # Strip exif data
  process :strip
  # Set quality of 80
  process :quality => 80
  # Process files as they are uploaded to no more than 800x600
  process :resize_to_fit => [800, 600], :if => :large_image?

  # Create different versions of your uploaded files:
  version :medium do
    process :resize_to_fit => [250, 250]
    process :quality => 70
  end

  version :square do
    process :resize_to_fill => [200, 200]
    process :quality => 70
  end

  version :small do
    process :resize_to_fill => [50, 50]
    process :quality => 80
    process :sharpen
  end

  #
  # END IMAGE PROCESSING AND SIZES
  #

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if Rails.env.production? || Rails.env.development?
      "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    else
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    # For Rails 3.1+ asset pipeline compatibility:
    asset_path([mounted_as, "default", "#{version_name}.png"].compact.join('_'))
  end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    @filename ||= "#{secure_token}.#{file.extension}" if original_filename
  end

  # returns true if dimensions greater than 800x600
  def large_image?(file)
    begin
      geo = self.geometry(file) # load geometry
      geo[0] > 800 or geo[1] > 600
    rescue
      false
    end
  end

  # Returns dimensions of file as array [width, height]
  def geometry(file)
    unless @geometry
      img = ::Magick::Image::read(file).first
      @geometry = [ img.columns, img.rows ]
    end
    @geometry
  end

  private

  def secure_token
    ivar = "@#{mounted_as}_secure_token"
    token = model.instance_variable_get(ivar)
    token ||= model.instance_variable_set(ivar, SecureRandom.hex(4))  
  end
end

# S3 upload
# In order to speed up your tests, it's recommended to switch off processing in your tests
if Rails.env.test? or Rails.env.cucumber?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end
end

if Rails.env.production?
  CarrierWave.configure do |config|
    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => Settings.aws.s3.access_key_id,
      :aws_secret_access_key  => Settings.aws.s3.secret_access_key,
      :region                 => 'us-east-1'  # optional, defaults to 'us-east-1'
    }
    config.fog_directory  =  Settings.aws.s3.bucket                  # required
    #config.fog_host       = 'https://assets.example.com'            # optional, defaults to nil
    #config.fog_public     = false                                   # optional, defaults to true
    config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
  end
elsif Rails.env.development?
  CarrierWave.configure do |config|
    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => 'fake',
      :aws_secret_access_key  => 'fake',
      :region                 => 'us-east-1'  # optional, defaults to 'us-east-1'
    }
    config.fog_directory  =  Settings.aws.s3.bucket                  # required
    config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
  end
end