class Youtube < Video
  # Pass in a url string
  # Formats:
  # http://www.youtube.com/watch?feature=player_embedded&v=2f70gxTUt5U
  # http://youtu.be/2f70gxTUt5U
  # http://www.youtube.com/embed/2f70gxTUt5U
  # and this will return the video id: 2f70gxTUt5U
  def self.id_from_url(url_string)
    begin
      uri = URI.parse(url_string)
      if uri.host == 'youtu.be' # url shortener version
        uri.path.sub(/^\//, '')
      elsif uri.path.match('embed') != nil # embed version
        uri.path.match(/[a-zA-Z0-9]*$/)[0]
      elsif uri.host.match('youtube.com') != nil # regular web url
        Hash[URI.decode_www_form(uri.query)]['v']
      else
        nil
      end
    rescue
      nil
    end
  end
  
    # Pass in a url string, and it will return the embed url
  def self.embed_url(url_string)
    id = Youtube.id_from_url(url_string)
    return '' if id.blank?
    Youtube.embed_url_for_id(id)
  end

   # Returns url string that can be used as iframe source to embed video
  def self.embed_url_for_id(id)
    # add &rel=0 so related videos aren't shown
    "http://www.youtube.com/embed/#{id}?rel=0"
  end

  def self.valid_url?(url_string)
    return !Youtube.embed_url(url_string).blank?
  end

  # Creates new Youtube object from Youtube url string
  def self.create_from_url(url_string)
    id = self.id_from_url(url_string)
    v = Youtube.new
    unless id.blank?
      v.external_id = id 
      v.save
    end
    v
  end

  def self.embed_code_html(embed_url, width, height)
    '<iframe width="' + width.to_s + '" height="' + height.to_s + '" src="' + embed_url + '" frameborder="0" allowFullScreen></iframe>'
  end

  def embed_code_html(width = 500, height = 315)
    Youtube.embed_code_html(self.embed_url, width, height)
  end

  def embed_url
    Youtube.embed_url_for_id(self.external_id)
  end

  def watch_url
    "http://www.youtube.com/watch?v=#{self.external_id}"
  end

  def save_external_video_locally
    self.save_file_locally
  end

  # Overwriting this because we need to use python script to save video
  def save_file_locally
    new_file_name = self.tmp_file_name('mp4')
    local_path_to_file = File.join(Video.tmp_file_dir, new_file_name)

    # Make sure dir exists
    FileUtils.mkdir_p(Video.tmp_file_dir) unless File.exists?(Video.tmp_file_dir)

    # simple one-liner using this great python script
    # doc: http://rg3.github.com/youtube-dl/documentation.html   I was passing -f 22 but not all videos are available in that format
    system("#{Rails.root}/script/youtube-dl.py -o #{local_path_to_file} '#{self.watch_url}'")

    self.local_file_path = local_path_to_file if File.exists?(local_path_to_file)
    if self.local_file_path.blank?
      raise "Local file could not be saved" 
    else
      return true
    end
  end
end