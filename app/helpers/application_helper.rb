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

    # Returns link to attached object
  def link_to_notification_object(title, notification)
    obj = notification.attachable
    return link_to(title, '#') if obj.blank? or notification.action.blank?
    case notification.action.to_sym
      when :new_checkin then link_to("#{obj.entity.name} completed their 'after' checkin", obj)
      when :relationship_request then link_to("#{obj.entity.name} would like to connect with you", relationships_path)
      when :relationship_approved then link_to("#{obj.connected_with.name} is now connected to you", startup_path(:id => obj.connected_with_id))
      when :new_comment then link_to("#{obj.user.name} commented on your #{obj.checkin.time_label} checkin", checkin_path(obj.checkin))
      when :new_nudge then link_to("#{obj.from.name} nudged you to complete your check-in", relationships_path)
      when :mentorship_approved then link_to("#{obj.entity.name} is now a mentor for you!", obj.entity)
      else link_to(title, '#')
    end
  end

  def user_avatar_url(user)
    return user.pic_url(:small) if user.pic?
    return user.external_pic_url unless user.external_pic_url.blank?
    return image_path('pic_default_small.png')
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
    html += "<p><small>#{obj.name.possessive} Community Status</small></p>"
    html += compact ? '<h3>' : '<h1>'
    html += "#{obj.rating.round(2)} "
    if obj.rating < 0.25
      html += link_to(Startup.community_status[0], community_guidelines_path, :class => "btn #{compact ? '' : 'btn-large'}") 
    elsif obj.rating >= 0.25 and obj.rating < 1
      html += link_to(Startup.community_status[1], community_guidelines_path, :class => "btn btn-warning #{compact ? '' : 'btn-large'}") 
    elsif obj.rating >= 1
      html += link_to(Startup.community_status[2], community_guidelines_path, :class => "btn btn-success #{compact ? '' : 'btn-large'}") 
    end
    html += compact ? '</h3>' : '</h1>'
    html
  end

  def format_profile_elements(elements)
    return '' if elements.blank?
    elements.map{|name, is_complete|
      ret = ''
      # if team then the value is an integer of % completeness
      if is_complete.is_a?(Float)
        if is_complete == 1.0
          ret += "&#x2713; #{name.to_s.titleize}"
        else
          ret += "#{name.to_s.titleize} #{(is_complete * 100).round}% complete"
        end
      # otherwise boolean
      else
        ret += (is_complete ? '&#x2713; ' : '') + name.to_s.titleize
      end
    }.join('<br />')
  end

  # returns boolean whether the field should be showd
  def show_user_field?(field)
    return true unless @setup or current_user.blank?
    return true if @setup and current_user.required_profile_elements.include?(field)
    return false
  end

  def external_url(url)
    url_for(ciao_path(:url => Base64.encode64(url)))
  end

  def link_to_external(title, url, options = {})
    # show modal to investors
    options.merge!(:target => '_blank')
    options.merge!(:class => 'external') if user_signed_in? && current_user.investor?
    link_to(title, external_url(url), options)
  end
end
