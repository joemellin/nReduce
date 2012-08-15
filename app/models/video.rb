class Video < ActiveRecord::Base
  belongs_to :checkin   # before/after video
  belongs_to :user      # profile video
  belongs_to :startup   # team video, pitch video

  attr_accessible :external_id, :user_id, :type, :vimeo_id

  validates_presence_of :external_id

  @queue = :video

  def self.tmp_file_dir
    File.join(Rails.root, 'tmp', 'videos')
  end

  def tmp_file_name(extension = 'mp4')
    # generate random token if new record, or just return id
    beginning = self.new_record? ? "#{Time.now.to_i}#{Random.rand(20)}" : self.id
    "#{beginning}.#{extension}"
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

    system("wget -O #{local_path_to_file} #{remote_url_str}")

    return
    # Wrap opening file to ensure it gets closed
    # could use open-uri: http://stackoverflow.com/questions/5386159/download-a-zip-file-through-nethttp
    begin

      download_file = open(local_path_to_file, "wb")
      url = URI.parse(remote_url_str)
      # May be better code for redirect following: http://stackoverflow.com/questions/5386159/download-a-zip-file-through-nethttp
      found = false
      until found
        host, port = url.host, url.port if url.host && url.port
        request = Net::HTTP.start(host, port, :use_ssl => url.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) 
        request.request_get(url.path) do |resp|
          # See if this is a redirect if so follow it
          resp.header['location'] ? url = URI.parse(resp.header['location']) : found = true
          # Otherwise save the file
          if found == true
            resp.read_body do |segment|
              download_file.write(segment)
              # hack to allow buffer to fille writes
              puts "segment"
              sleep 0.005
            end
          end
        end
        puts url.inspect
      end
    ensure
      download_file.close
    end
    self.local_file_path = local_path_to_file if File.exists?(local_path_to_file)
    if self.local_file_path.blank?
      raise "Local file could not be saved" 
    else
      return true
    end
  end


  # Transfers a local file (using local_file_path) to vimeo account
  # Adds vimeo_id to model on success - does not save
  # delete_on_success will delete the local file if it is successfully uploaded
  def upload_to_vimeo(delete_on_success = false)

    # Vimeo upload
    begin
      upload = Vimeo::Advanced::Upload.new(Settings.apis.vimeo.client_id, Settings.apis.vimeo.client_secret, :token => Settings.apis.vimeo.access_token, :secret => Settings.apis.vimeo.access_token_secret)
      uploaded_video = upload.upload(self.local_file_path)
      
      # Store vimeo id
      self.vimeo_id = uploaded_video['ticket']['video_id']
      
      video = Vimeo::Advanced::Video.new(Settings.apis.vimeo.client_id, Settings.apis.vimeo.client_secret, :token => Settings.apis.vimeo.access_token, :secret => Settings.apis.vimeo.access_token_secret)
      
      # hide from vimeo.com
      video.set_privacy(uploaded_video['ticket']['video_id'], "disable", { :users => nil, :password => nil })
      
      # set video title
      video.set_title(uploaded_video['ticket']['video_id'], self.created_at.to_s)
    rescue => e
      raise e
    end

    # Remove local file
    FileUtils.rm(self.local_file_path) if delete_on_success if !self.vimeo_id.blank?
  end

  # Method to take the external video and save it to our vimeo account
  # First it saves it locally, then it uploads to vimeo, finally saves object
  def download_and_transfer_to_vimeo!
    # Use individually implemented method to save file locally
    self.save_external_video_locally
    # Transfer to vimeo
    self.upload_to_vimeo(true)
    raise "Vimeo: video could not be uploaded from local file: #{path_to_local_file}" if self.vimeo_id.blank?
    self.save
  end
end
