module ApplicationHelper
  def js_settings
    %{
      <script type="text/javascript" charset="utf-8">
        window.Settings = {};
        Settings.env = "#{Rails.env}";
        Settings.client = #{Settings.client.to_hash.to_json};
      </script>
    }.html_safe
  end


  # set attributes that display on the body
  def body_attrs(val = nil)
    @body_attrs ||= {}
    @body_attrs = @body_attrs.with_indifferent_access

    # merge values
    @body_attrs.merge!(val.with_indifferent_access) if val.is_a?(Hash)

    @body_attrs
  end

  # add css class
  def error_css(model, field)
    return unless model.present?

    css_classes = []

    css_classes << "with-errors" if model.errors[field].present?

    {
      :class => css_classes.join(" ")
    }
  end

  def agree_error_msg(model, field)
    return unless model.present?

    if model.errors[field].present?
      %{
        <ul class="errors">
          <li>Required. Please read and select a response.</li>
        </ul>
      }.html_safe
    end
  end

  def link_to_twitter(handle = '', opts = {})
    return '' if handle.blank?
    link_to(handle, url_for_twitter(handle), opts)
  end

  def url_for_twitter(handle)
    "https://twitter.com/#!/#{handle.sub('@', '')}"
  end

  def is_controller_action?(controller_name, action_name = nil)
    return true if controller.controller_name == controller_name and action_name.blank?
    controller.controller_name == controller_name and controller.action_name == action_name
  end

    # Given a time object, returns a verbose result of how many days, hours, minutes, seconds
  def verbose_distance_until_time_from_now(time)
    return '' if time.blank?
    arr = distance_until_time_from_now_arr(time)
    ret = []
    ret.push(pluralize(arr[0], 'day')) unless arr[0] == 0
    ret.push(pluralize(arr[1], 'hour')) unless arr[1] == 0
    ret.push(pluralize(arr[2], 'min')) unless arr[2].blank?
    ret.join(', ') + ' and ' + pluralize(arr[3], 'sec')
  end

  def distance_until_time_from_now_arr(time)
    return [] if time.blank?
    from_time = Time.now
    to_time = time
    seconds = ((to_time - from_time).abs).round
    days = (seconds / 86400).floor
    seconds -= 86400 * days
    hours = (seconds / 3600).floor
    seconds -= 3600 * hours
    minutes = (seconds / 60).floor
    seconds -= 60 * minutes
    return [days, hours, minutes, seconds]
  end

    # Returns array of [pic_url, title, url_path] for a notification
  def elements_for_notification(notification)
    obj = notification.attachable
    return [nil, notification.message, nil] if obj.blank? or notification.action.blank?
    case notification.action.to_sym
      when :new_checkin then [obj.startup.logo_url(:small), "<span class='entity'>#{obj.startup.name}</span> posted their weekly progress update", url_for(obj)]
      when :relationship_request then [obj.entity.is_a?(Startup) ? obj.entity.logo_url(:small) : obj.entity.pic_url(:small), "<span class='entity'>#{obj.entity.name}</span> would like to connect with you", url_for(obj.entity)]
      when :relationship_approved then [obj.connected_with.is_a?(Startup) ? obj.connected_with.logo_url(:small) : obj.connected_with.pic_url(:small), "<span class='entity'>#{obj.connected_with.name}</span> is now connected to you", url_for(obj.connected_with)]
      when :new_comment_for_checkin then [obj.user.pic_url(:small), "<span class='entity'>#{obj.user.name}</span> commented on your #{obj.checkin.time_label} checkin", checkin_path(obj.checkin) + "#c#{obj.id}"]
      when :new_nudge then [obj.from.pic_url(:small), "<span class='entity'>#{obj.from.name}</span> nudged you to complete your check-in", url_for(obj.from)]
      when :new_comment_for_post then [obj.user.pic_url(:small), "<span class='entity'>#{obj.user.name}</span> commented on your post", post_path(:id => obj.root_id)]
      when :new_like then [obj.user.pic_url(:small), "<span class='entity'>#{obj.user.name}</span> likes your post", post_path(obj)]
      when :new_team_joined then [obj.logo_url(:small), "<span class='entity'>#{obj.name}</span> joined nReduce", url_for(obj)]
      when :new_awesome then [obj.user.pic_url(:small), "<span class='entity'>#{obj.user.name}</span> thinks you made some awesome progress!", url_for(obj.awsm)]
      when :response_completed then [obj.user.pic_url(:small), "<span class='entity'>#{obj.user.name}</span> completed your help request!", url_for(obj.user)]
      else [nil, notification.message, nil]
    end
  end 


  def user_avatar_url(user, size = :small)
    return user.pic_url(size) if user.pic?
    return user.external_pic_url unless user.external_pic_url.blank?
    return image_path("pic_default_#{size}.png")
  end

  # this seems to be broken for some reason
  def video_embed_tag(youtube_url, width = '500', height = '315')
    embed_url = Youtube.embed_url(youtube_url)
    return '' if embed_url.blank?
    tag(:iframe, {:width => width, :height => height, :src => embed_url, :frameborder => 0, :allowfullscreen => true})
  end

  def rating_link(obj, compact = false)
    html = ''
    return html if !obj.respond_to?(:rating)
    # Set as 0 if nil
    obj.rating ||= 0
    html += compact ? '<h3>' : '<h1>'
    html += "#{obj.rating.round(2)} "
    html += compact ? '</h3>' : '</h1>'
    html += compact ? '<p>' : '<p>'
    html += link_to('Community Rating', community_guidelines_path,) 
    html += compact ? '</p>' : '</p>'
    html
  end

  def format_profile_elements(elements)
    return '' if elements.blank?
    r = ['']
    elements.each do |name, is_complete|
      ret = ''
      # if team member with attributes then grab embedded hash
      if is_complete.is_a?(Hash)
        team_mate = format_profile_elements(is_complete)
        unless team_mate.blank?
          ret += "<strong>#{name.to_s.titleize}</strong>#{team_mate}" 
        end
      else
        # if team then the value is an integer of % completeness
        if is_complete.is_a?(Float)
          unless is_complete == 1.0
            ret += "#{name.to_s.titleize} #{(is_complete * 100).round}% complete"
          end
        # otherwise boolean
        elsif !is_complete
          ret += name.to_s.titleize
        end
      end
      r << ret unless ret.blank? 
    end
    r.join('<br />')
  end

  # returns boolean whether the field should be showd
  def show_user_field?(field)
    return true unless @setup or current_user.blank?
    return true if @setup and current_user.required_profile_elements.include?(field)
    return false
  end

  def external_url(url, source = nil)
    if source.present?
      url_for(ciao_path(:url => Base64.encode64(url), :source => source))
    else
      url_for(ciao_path(:url => Base64.encode64(url)))
    end
  end

  def link_to_external(title, url, options = {})
    # show modal to investors
    options.merge!(:target => '_blank')
    options.merge!(:class => 'external') if user_signed_in? && current_user.investor?
    link_to(title, external_url(url, options[:source]), options)
  end

  def background_image_path
    url = nil
    url = Settings.coworking_locations.uptown_espresso.images[4] if ['startups', 'users'].include?(controller.controller_name) && controller.action_name == 'edit'
    url = Settings.coworking_locations.uptown_espresso.images[3] if controller.controller_name == 'posts'
    url = Settings.coworking_locations.uptown_espresso.images[2] if ['startups', 'users'].include?(controller.controller_name) && controller.action_name == 'show'
    url = Settings.coworking_locations.uptown_espresso.images[2] if controller.controller_name == 'checkins'
    url = Settings.coworking_locations.uptown_espresso.images[1] if ['investors', 'ratings'].include?(controller.controller_name)
    url ||= Settings.coworking_locations.uptown_espresso.images[0]
    "http://assets.nreduce.com/coworking/#{url}"
  end

  def show_background_image?
    user_signed_in? && !@setup && !@demo_day && !@hide_background_image
  end
end
