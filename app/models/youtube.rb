class Youtube
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
    "http://www.youtube.com/embed/#{id}"
  end
  
  def self.valid_url?(url_string)
    return !Youtube.embed_url(url_string).blank?
  end
end