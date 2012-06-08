class Vimeo
  def self.id_from_url(url_string)
    uri = URI.parse(url_string)
    if uri.host.match('vimeo.com') != nil # regular web url
      uri.path.match(/[a-zA-Z0-9]+/)[0]
    else
      nil
    end
  end

    # Pass in a url string, and it will return the embed url
  def self.embed_url(url_string)
    "http://player.vimeo.com/video/#{Vimeo.id_from_url(url_string)}"
  end

  def self.is_vimeo_url?(url_string)
    uri = URI.parse(url_string)
    return uri.host.match(/(vimeo\.com)$/) != nil if !uri.host.blank?
    false
  end
end