class ViddlerVideo < Video
  after_destroy :remove_from_viddler

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
    flashvars = "fake=1&recordToken=#{token}&recQuality=M&enableCallbacks=1"
    '<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000"  codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0" width="449" height="545"
id="viddler_recorder" align="middle" style="display: inline-block">
      <param name="allowScriptAccess" value="always" />
      <param name="allowNetworking" value="all" />
      <param name="movie" value="http://cdn-static.viddler.com/flash/recorder.swf" />
      <param name="quality" value="high" />
      <param name="scale" value="noScale" />
      <param name="bgcolor" value="#000000" />
      <param name="flashvars" value="' + flashvars + '" />
      <embed src="http://cdn-static.viddler.com/flash/recorder.swf" quality="high" scale="noScale" bgcolor="#000000"
allowScriptAccess="always" allowNetworking="all" width="449" height="400" name="viddler_recorder"
flashvars="' + flashvars + '" align="middle" allowScriptAccess="sameDomain"
type="application/x-shockwave-flash"  pluginspage="http://www.macromedia.com/go/getflashplayer" style="display: inline-block" />
    </object>'
  end

  def embed_code_html(width = 437, height = 370)
    '<object width="' + width.to_s + '" height="' + height.to_s + '" data="http://www.viddler.com/simple/key" type="application/x-shockwave-flash">
      <param name="id" value="publisher" />
      <param name="align" value="middle" />
      <param name="flashvars" value="key=' + self.external_id + '" />
      <param name="allowscriptaccess" value="always" />
      <param name="allownetworking" value="all" />
      <param name="allowfullscreen" value="true" />
      <param name="scale" value="noscale" />
      <param name="quality" value="high" />
      <param name="wmode" value="transparent" />
      <param name="src" value="http://www.viddler.com/simple/key" />
      <param name="name" value="publisher" />
    </object>'
  end

  def save_external_video_locally
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

  protected

  def remove_from_viddler
    begin
      ViddlerVideo.client.post('viddler.videos.delete', :video_id => self.external_id)
    rescue
      logger.info "Couldn't delete Viddler Video with id #{self.external_id}."
    end
  end
end