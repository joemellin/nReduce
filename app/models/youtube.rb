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

  def embed_code_html(width = 500, height = 315)
    '<iframe width="' + width.to_s + '" height="' + height.to_s + '" src="' + self.embed_url + '" frameborder="0" allowfullscreen></iframe>'
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


  # LOTS OF OLD attempts at tryig to download youtube video
  # Generates download link from external id and then triggers super method to save video locally
  def save_external_video_locally_old
    # First we have to get the token from youtube to download the video
    uri = URI.parse('http://www.youtube.com/get_video_info?&video_id=' + self.external_id)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    body = CGI::parse(response.body) unless response.body.blank?
    token = body['token'].first unless body.blank?
    raise "Youtube: could not get token for video with id #{self.external_id}" if token.blank?
    # Now we can get the video
    # Youtube quality formats: http://en.wikipedia.org/wiki/Youtube#Quality_and_codecs
    # fmt=18 is mp4 360p
    # fmt=22 is mp4 720p

    # http://www.longtailvideo.com/support/forums/jw-player/setup-issues-and-embedding/10404/youtube-blocked-httpyoutubecomgetvideo
    url = "http://www.youtube.com/get_video?video_id=#{self.external_id}&t=#{token}&fmt=18" #&l=#{body['l'].first}&sk=#{body['sk'].first}"

    uri = URI.parse(url)
    puts url
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    return response.headers

    rh = CGI::parse(response)
    rh.each do |k,v|
      puts "#{k} -- #{v}"
    end
    return
    self.save_file_locally("http://www.youtube.com/get_video?video_id=#{self.external_id}&t=#{token}&fmt=18", 'mp4')
    puts self.local_file_path
    return

    uri = URI.parse(Youtube.download_url_for_id(self.external_id))
    http = Net::HTTP.new(uri.host, uri.port)
    FileUtils.touch '/Users/josh/Projects/nreduce/tmp/video/sample.flv'
    open('/Users/josh/Projects/nreduce/tmp/video/sample.flv')
    http.request_get(uri.path) do |resp|
      resp.read_body do |segment|
        f.write(segment)
      end
    end
    f.close
    return


    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    puts response.inspect
    self.save_file_locally(Youtube.download_url_for_id(self.external_id), 'flv')



    # First we have to get the valid urls
    # http://stackoverflow.com/questions/4602956/youtube-get-video-not-working
    m = Mechanize.new
    page = m.get('http://www.youtube.com/get_video_info?&video_id=' + self.external_id)
    puts m.cookie_jar.inspect
    body = CGI.parse(page.body) unless page.body.blank?
    urls_tmp = body['url_encoded_fmt_stream_map'].first.split(',').map{|url| url.sub(/^url=/, '') }
    c = 0
    urls_tmp.each do |u|
      begin
        puts CGI.unescape(u)
        m.get(CGI.unescape(u)).save_as "/Users/josh/Projects/nreduce/tmp#{c}.flv"
        puts m.cookie_jar.inspect
      rescue
        # nothing
      end
      c += 1
    end
    return 'done'



    uri = URI.parse('http://www.youtube.com/get_video_info?&video_id=' + self.external_id)
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    cookie = response.response['set-cookie']
    puts "Cookie: #{cookie}"
    body = CGI.unescape(response.body) unless response.body.blank?
    body = CGI::parse(response.body) unless body.blank?
    raise "Youtube: could not get url to download from video response" if body.blank? || body['url_encoded_fmt_stream_map'].blank?
    urls_tmp = body['url_encoded_fmt_stream_map'].first.split(',').map{|url| url.sub(/^url=/, '') }
    puts urls_tmp.first
    download_file = open('/Users/josh/Projects/nreduce/tmp.flv', "wb")
    url = URI.parse(urls_tmp.first)
    request = Net::HTTP.start(url.host, url.port)
    request.request_get(url.path, {"Cookie" => cookie}) do |resp|
      resp.read_body do |segment|
        download_file.write(segment)
        # hack to allow buffer to fille writes
        sleep 0.005
      end
    end
    download_file.close
    return

    self.save_file_locally(urls_tmp.first, 'flv', {"Cookie" => cookie})
    #raise "Youtube: could not get token for video with id #{self.external_id}" if token.blank?
    # Now we can get the video
    # Youtube quality formats: http://en.wikipedia.org/wiki/Youtube#Quality_and_codecs
    # fmt=18 is mp4 360p
    # fmt=22 is mp4 720p
  end
end