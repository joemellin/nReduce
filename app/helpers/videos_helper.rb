module VideosHelper
  def display_video(video)
    # If this video is on vimeo display it
    if video.vimeod? && !video.vimeo_id.blank?
      content_tag :div, 'Loading video...', :class => 'js-vimeo', 'data-url' => "https://vimeo.com/#{video.vimeo_id}"
    elsif video.type == 'ViddlerClient'
      '[ Viddler Video ]'
    elsif video.type == 'Youtube'
      tag :iframe, :width => '500', :height => '315', :src => video.embed_url, :frameborder => 0, :allowfullscreen => true
    elsif video.type == 'Screenr'
      '[ Screenr Video ]'
    else
      '[ Video ]'
    end
  end
end
  
      