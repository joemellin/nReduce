class Screenr < Video
  
  def embed_code_html(width = 500, height = 315)
    "<iframe src='https://nreduce.viewscreencasts.com/embed/#{self.external_id}' width='#{width}' height='#{height}' frameborder='0'></iframe>"
  end

  def save_external_video_locally
    # return true if already uploaded
    return true if !self.vimeo_id.blank? && !force_upload
    # Set video as downloadable
    details = ViddlerVideo.client.post('viddler.videos.set_details', :video_id => self.external_id, :download_perm => 'public')
    raise "Viddler: Video with id #{self.external_id} doesn't exist or isn't encoded yet" if details.blank? || details['video']['files'].blank?
    raise "Viddler: could not set video as downloadable" unless details['video']['permissions']['download']['level'] == 'public'
    # First get html5 video source
    remote_url = extension = nil
    details['video']['files'].each do |f|
      if f['profile_name'].match(/source/i) != nil
        remote_url = f['url']
        extension = f['ext']
      end 
    end
    raise "Viddler: did not return html5 video source" if remote_url.blank?
    # Save it locally
    self.save_file_locally(remote_url, extension)
  end
end