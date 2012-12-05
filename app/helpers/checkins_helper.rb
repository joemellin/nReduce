module CheckinsHelper
  # Helper method to display a checkin video embed
  # Pass in the checkin, video type (:before_video or :video)
  # show_image to true will prioritize showing an image if it exists
  def display_checkin_video(checkin, video = :before_video, show_image = false, width = 500, height = 315, small_x = false)
    if video == :before_video
      if checkin.before_video_id.present?
        return display_video(checkin.before_video, show_image, width, height)
      # Youtube url?
      elsif checkin.start_video_url.present?
        return display_video_from_youtube_url(checkin.start_video_url, width, height)
      else
        return image_tag(small_x ? 'novideo_s.png' : 'novideo.png', :style => "width: #{width}px; height: #{height}px;")
      end
    elsif video == :video
      if checkin.video_id.present?
        return display_video(checkin.video, show_image, width, height)
      # Youtube url?
      elsif checkin.end_video_url.present?
        return display_video_from_youtube_url(checkin.end_video_url, width, height)
      else
        return image_tag(small_x ? 'novideo_s.png' : 'novideo.png', :style => "width: #{width}px; height: #{height}px;")
      end
    end
    ''
  end

  def display_video(video, show_image = false, width = 500, height = 315, small_x = false)
    if video.blank?
      image_tag(small_x ? 'novideo_s.png' : 'novideo.png', :style => "width: #{width}px; height: #{height}px;")
    elsif video.present? && show_image && video.image?
      image_tag video.image.url(:medium), :width => width, :height => height
    else
      video.embed_code(width, height)
    end
  end

  def display_video_from_youtube_url(youtube_url, width = 500, height = 315)
    embed_url = Youtube.embed_url(youtube_url)
    return '' if embed_url.blank?
    Youtube.embed_code_html(embed_url, width, height)
  end

  def hours_minutes_until(time)
    diff = (time - Time.now).round
    hours = diff / 3600
    minutes = (diff - (hours * 3600)) / 60
    text = ''
    text += "#{hours}h " if hours > 0
    text += "#{minutes}m Remaining"
    text
  end

  def awesome_comment_count_summary(checkin)
    ret = []
    ret << pluralize(checkin.comment_count, 'comment') if checkin.comment_count > 0
    ret << pluralize(checkin.awesome_count, 'awesome') if checkin.awesome_count > 0
    return '' if ret.blank?
    ret = ret.to_sentence
    ret + ' from:'
  end
end
