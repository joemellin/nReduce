module CheckinsHelper
  # Helper method to display a checkin video embed
  # Pass in the checkin, video type (:before_video or :after_video)
  # show_image to true will prioritize showing an image if it exists
  def display_checkin_video(checkin, video = :before_video, show_image = false, width = 500, height = 315)
    if video == :before_video
      if checkin.before_video_id.present?
        return display_video(checkin.before_video, show_image, width, height)
      # Youtube url?
      elsif checkin.start_video_url.present?
        return display_video_from_youtube_url(checkin.start_video_url, width, height)
      else
        return image_tag('novideo_s.png')
      end
    elsif video == :after_video
      if checkin.after_video_id.present?
        return display_video(checkin.after_video, show_image, width, height)
      # Youtube url?
      elsif checkin.end_video_url.present?
        return display_video_from_youtube_url(checkin.end_video_url, width, height)
      else
        return image_tag('novideo_s.png')
      end
    end
    ''
  end

  def display_video(video, show_image = false, width = 500, height = 315)
    if show_image && video.image?
      image_tag video.image.url(:medium), :width => width, :height => height
    else
      video.embed_code(width, height)
    end
  end

  def display_video_from_youtube_url(youtube_url, width = 500, height = 315)
    embed_url = Youtube.embed_url(youtube_url)
    return '' if embed_url.blank?
    tag(:iframe, {:width => width, :height => height, :src => embed_url, :frameborder => 0, :allowfullscreen => true})
  end
end
