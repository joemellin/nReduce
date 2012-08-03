class ViddlerClient < Video
  @@client = nil

  def self.client
    @@client ||= Viddler::Client.new(Settings.apis.viddler.key)
    # Authorize to perform actions on our account
    @@client.authenticate! Settings.apis.viddler.username, Settings.apis.viddler.password, true
    @@client
  end

  # Returns a valid record token as a string
  def self.record_token
    self.client.record_token
  end

  # Returns html for the embedded flash recorder
  # max_length in seconds allowed for the video
  # Doc here: http://developers.viddler.com/documentation/articles/howto-record/
  def self.embedded_recorder_html(max_length = 30)
    token = self.record_token
    return '' if token.blank?
    '<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"  codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" width="449" height="545"
id="viddler_recorder" align="middle">
      <param name="allowScriptAccess" value="always" />
      <param name="allowNetworking" value="all" />
      <param name="movie" value="http://cdn-static.viddler.com/flash/recorder.swf" />
      <param name="quality" value="high" />
      <param name="scale" value="noScale">
      <param name="bgcolor" value="#000000" />
      <param name="recQuality" value="H">
      <param name="enableCallbacks" value="Y">
      <param name="flashvars" value="fake=1&recordToken=[YourRecordTokenHere]" />
      <embed src="http://cdn-static.viddler.com/flash/recorder.swf" quality="high" scale="noScale" bgcolor="#000000"
allowScriptAccess="always" allowNetworking="all" width="449" height="545" name="viddler_recorder"
flashvars="fake=1&recordToken=' + token + '" align="middle" allowScriptAccess="sameDomain"
type="application/x-shockwave-flash"  pluginspage="http://www.macromedia.com/go/getflashplayer" />
    </object>'
  end

  # Method to take the viddler video and save it to our vimeo account
  # First it saves it locally, then it uploads to vimeo, finally saves object
  def transfer_to_vimeo!(force_upload = false)
    # return true if already uploaded
    return true if !self.vimeo_id.blank? && !force_upload
    details = ViddlerClient.client.get('viddler.videos.get_details', :video_id => self.external_id)
    raise "Viddler: Video with id #{self.external_id} doesn't exist or isn't encoded yet" if details.blank?
    # First get html5 video source
    remote_url = details['video']['html5_video_source']
    remote_url += '?sessionid' + ViddlerClient.client.sessionid + '&key=' + ViddlerClient.client.api_key
    puts remote_url
    raise "Viddler: did not return html5 video source" if remote_url.blank?
    # Save it locally
    self.save_file_locally(remote_url, 'mp4')
    raise "Local file could not be saved" if self.local_file_path.blank?
    # Transfer to vimeo
    self.upload_to_vimeo(true)
    raise "Vimeo: video could not be uploaded from local file: #{path_to_local_file}" if self.vimeo_id.blank?
    self.save
  end
end