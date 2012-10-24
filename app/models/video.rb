class Video < ActiveRecord::Base
  belongs_to :checkin   # before/after video
  belongs_to :user      # profile video
  belongs_to :startup   # team video, pitch video

  attr_accessible :external_id, :user_id, :type, :vimeo_id, :image, :remote_image_url, :image_cache, :external_url, :youtube_url
  attr_accessor :youtube_url
  attr_accessor :force_queue_to_vimeo

  before_validation :extract_id_from_youtube_url
  after_create :force_queue_to_vimeo
  before_save :queue_transfer_to_vimeo
  after_destroy :remove_from_vimeo_and_delete_local_file

  validates_presence_of :external_id, :message => 'URL is not valid'
  validate :video_is_unique

  scope :vimeod, where(:vimeod => true)

  mount_uploader :image, BaseUploader # carrierwave file uploads

  @queue = :video

  def self.tmp_file_dir
    File.join(Rails.root, 'tmp', 'videos')
  end

  def tmp_file_name(extension = 'mp4')
    # generate random token if new record, or just return id
    beginning = self.new_record? ? "#{Time.now.to_i}#{Random.rand(20)}" : self.id
    "#{beginning}.#{extension}"
  end

  # Method to get embed code - no matter what kind of video
  def embed_code(width = 500, height = 315)
    if self.vimeod?
      '<iframe src="http://player.vimeo.com/video/' + self.vimeo_id.to_s + '?api=1&player_id=video_' + self.id.to_s + '&title=0&byline=0&portrait=0" id="video_' + self.id.to_s + '" width="' + width.to_s + '" height="' + height.to_s + '" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>'
    else
      self.embed_code_html(width, height)
    end
  end

  # Mock - this method should return a string of html to play the video
  def embed_code_html(width = 500, height = 315)
    '[video saved - will display when done]'
  end

  # Mock - to be implemented on any external video classes that inherit from the Video class
  def save_external_video_locally
    #self.save_file_locally
  end

  # Given a location of a file on a remote server it will save it locally to the tmp_file_dir
  # DOES NOT SAVE model
  # Will follow redirects
  def save_file_locally(remote_url_str, extension = nil)
    extension ||= remote_url_str.match(/\.\w+$/)[0].sub(/^\./, '')
    new_file_name = self.tmp_file_name(extension)
    local_path_to_file = File.join(Video.tmp_file_dir, new_file_name)

    # Make sure dir exists
    FileUtils.mkdir_p(Video.tmp_file_dir) unless File.exists?(Video.tmp_file_dir)

    # simple one-liner because using net/http just doesn't seem to work
    system("wget -O #{local_path_to_file} #{remote_url_str}")

    self.local_file_path = local_path_to_file if File.exists?(local_path_to_file)
    if self.local_file_path.blank?
      raise "Local file could not be saved" 
    else
      return true
    end
  end

  ## VIMEO SPECIFIC METHODS

  # Authenticated Vimeo client
  def self.vimeo_client
    Vimeo::Advanced::Video.new(Settings.apis.vimeo.client_id, Settings.apis.vimeo.client_secret, :token => Settings.apis.vimeo.access_token, :secret => Settings.apis.vimeo.access_token_secret)
  end

  # Method to take the external video and save it to our vimeo account
  # First it saves it locally, then it uploads to vimeo, finally saves object (adds vimeo_id to object on success)
  def transfer_to_vimeo!
    return true if self.vimeo_id.present?
    # Use individually implemented method to save file locally
    self.save_external_video_locally
    # Upload to vimeo
    begin
      upload = Vimeo::Advanced::Upload.new(Settings.apis.vimeo.client_id, Settings.apis.vimeo.client_secret, :token => Settings.apis.vimeo.access_token, :secret => Settings.apis.vimeo.access_token_secret)
      uploaded_video = upload.upload(self.local_file_path)
      
      # Store vimeo id
      self.vimeo_id = uploaded_video['ticket']['video_id']
      
      self.set_desired_vimeo_permissions unless self.vimeo_id.blank?
    rescue => e
      raise e
    end

    # Remove local file
    if self.vimeo_id.present?
      FileUtils.rm(self.local_file_path)
      self.local_file_path = nil
    end
    
    # Ensure upload completed successfully
    raise "Vimeo: video could not be uploaded from local file: #{path_to_local_file}" if self.vimeo_id.blank?
    
    # Save vimeo id
    self.save

    # Check to see if it has been encoded & grab thumbnail images - it can take a while on vimeo
    Resque.enqueue_in(20.minutes, Video, self.id)
  end

  # Set privacy on vimeo
  def set_desired_vimeo_permissions
    begin
      video = Vimeo::Advanced::Video.new(Settings.apis.vimeo.client_id, Settings.apis.vimeo.client_secret, :token => Settings.apis.vimeo.access_token, :secret => Settings.apis.vimeo.access_token_secret)
        
      # hide from vimeo.com
      video.set_privacy(self.vimeo_id, "disable", { :users => nil, :password => nil })
      
      # set embed preset to remove vimeo logo and add ours
      video_embed = Vimeo::Advanced::VideoEmbed.new(Settings.apis.vimeo.client_id, Settings.apis.vimeo.client_secret, :token => Settings.apis.vimeo.access_token, :secret => Settings.apis.vimeo.access_token_secret)
      video_embed.set_preset(self.vimeo_id, Settings.apis.vimeo.preset_id)

      # set video title
      video.set_title(self.vimeo_id, "#{self.id} - #{self.created_at.to_s}")
    rescue
      return false
    end
    true
  end

  # Get details of video from Vimeo API
  def vimeo_details
    return nil if self.vimeo_id.blank?
    response = Video.vimeo_client.get_info(self.vimeo_id)
    return !response['video'].blank? ? response['video'].first : nil
  end

  # Check if encoded on vimeo, save thumbnail url
  def check_if_encoded_and_get_thumbnail_urls(queue_again = false)
    details = self.vimeo_details
    return false if details.blank?
    # If it's already been tried twice just re-upload it
    if self.ecc >= 2
      self.ecc = 0
      self.redo_vimeo_transfer
    else
      # Set as transcoded if it has completed
      self.vimeod = true if details['is_transcoding'].to_i == 0
      # Save image thumbnails
      if details['thumbnails'].present? && details['thumbnails']['thumbnail'].present? && details['thumbnails']['thumbnail'].last['_content'].match(/default\..*\.jpg/) == nil
        self.remote_image_url = details['thumbnails']['thumbnail'].last['_content']
      elsif queue_again
        self.ecc += 1
        Resque.enqueue_in(20.minutes, Video, self.id) # queue to check and see if it got encoded
        false
      end
      self.save
    end
  end

  # Downloads video and transfers to Vimeo
  def self.perform(video_id)
    v = Video.find(video_id)
    # Return if already completed transfer to Vimeo (right now no way to force re-encode)
    return true if v.vimeod?
    begin
      if v.vimeo_id.present?
        v.check_if_encoded_and_get_thumbnail_urls(true)
      else
        # Transfer it to vimeo and queue encoding check
        v.transfer_to_vimeo! 
      end
    rescue
      # Fails to download or video hasn't encoded yet
    end
  end

  def queue_transfer_to_vimeo(force_transfer = false)
    Resque.enqueue(Video, self.id) if force_transfer || (self.external_id_changed? && !self.new_record?)
    true
  end

  # need this method so I can use it in after_create callback
  def force_queue_to_vimeo
    self.queue_transfer_to_vimeo(true)
    true
  end

  def redo_vimeo_transfer
    self.remove_from_vimeo_and_delete_local_file
    self.save
    self.force_queue_to_vimeo
  end

  # Will find all videos that have been transfered to vimeo but not successfully encoded and try uploading them again.
  def self.redo_failed_vimeo_transfers
    Video.where('vimeo_id IS NOT NULL AND vimeod = 0').each{|v| v.redo_vimeo_transfer }
  end

  # END VIMEO-SPECIFIC METHODS

  protected

  # Pulls youtube id from youtube_url attribute
  def extract_id_from_youtube_url
    if self.youtube_url.present?
      url = self.youtube_url
      self.external_id = Youtube.id_from_url(url) if url.present?
      self.errors.add(:youtube_url, 'is not a valid Youtube URL') unless self.external_id.present?
    else
      true
    end
  end

  # Make sure there isn't another video already stored with same external id
  def video_is_unique
    if self.new_record? && self.external_id.present? && Video.where(:external_id => self.external_id, :type => self.class.to_s).count > 0
      self.errors.add(:external_id, 'is not unique')
      false
    else
      true
    end
  end

  def remove_from_vimeo_and_delete_local_file
    # Remove video from vimeo
    begin
      if self.vimeo_id.present?
        video = Vimeo::Advanced::Video.new(Settings.apis.vimeo.client_id, Settings.apis.vimeo.client_secret, :token => Settings.apis.vimeo.access_token, :secret => Settings.apis.vimeo.access_token_secret)
        video.delete(self.vimeo_id)
      end
      FileUtils.rm(self.local_file_path) if self.local_file_path.present? && File.exists?(self.local_file_path)
      self.vimeo_id = nil
      self.vimeod = false
    rescue
      logger.info "Couldn't delete Vimeo Video with id #{self.vimeo_id}."
    end
    true
  end
end
