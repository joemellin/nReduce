class Video < ActiveRecord::Base
  belongs_to :checkin   # before/after video
  belongs_to :user      # profile video
  belongs_to :startup   # team video, pitch video

  attr_accessible :external_id, :user_id, :type, :vimeo_id

  validates_presence_of :user_id
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

  # Given a location of a file on a remote server it will save it locally to the tmp_file_dir
  # DOES NOT WORK with files over SSL yet
  # DOES NOT SAVE model
  def save_file_locally(remote_url_str, extension = nil)
    extension ||= remote_url_str.match(/\.\w+$/)[0].sub(/^\./, '')
    new_file_name = self.tmp_file_name(extension)
    local_path_to_file = File.join(Video.tmp_file_dir, new_file_name)
    uri = URI.parse(remote_url_str)
    Net::HTTP.start(uri.host, uri.port) do |http|
      begin
        file = open(local_path_to_file, 'wb')
        http.request_get(uri.path) do |response|
          response.read_body do |segment|
            file.write(segment)
          end
        end
     
      ensure
        file.close
      end
    end
    self.local_file_path = local_path_to_file if File.exists?(local_path_to_file)
    return self.local_file_path.blank? ? true : false
  end

  # Transfers a local file to vimeo account
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
end
