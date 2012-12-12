module AwesomesHelper
  def render_like_button(object)
    return '' unless user_signed_in?
    awesome_id = current_user.awesome_id_for_object(object)
    ret = '<span id=' + Awesome.unique_id_for_object(object) + '>'
    if awesome_id.blank?
      ret += link_to("<i class=\"icon-thumbs-up icon\"></i>".html_safe, "/awesomes/?awsm_type=#{object.class.to_s}&awsm_id=#{object.id}", :remote => true, :method => :post, :class => 'btn', :title => 'Like')
    else
      ret += link_to("<i class=\"icon-thumbs-up icon-white\"></i>".html_safe, awesome_path(:id => awesome_id), :remote => true, :method => :delete, :class => 'btn btn-info', :title => 'You liked this')
    end
    ret += '</span>'
    ret
  end

  def render_awesome_button(object)
    return '' unless user_signed_in?
    return '' if object.user_id == current_user.id
    label = Awesome.label_for_type(object.class.to_s)
    awesome_id = current_user.awesome_id_for_object(object)
    ret = '<div id=' + Awesome.unique_id_for_object(object) + '>'
    if awesome_id.blank?
      ret += link_to("<i class=\"icon-thumbs-up icon\"></i> #{label}".html_safe, "/awesomes/?awsm_type=#{object.class.to_s}&awsm_id=#{object.id}", :remote => true, :method => :post, :class => 'btn')
    else
      ret += link_to("<i class=\"icon-ok\"></i> #{label}d".html_safe, awesome_path(:id => awesome_id), :remote => true, :method => :delete, :class => 'btn disabled')
    end
    # if object.awesome_count > 0
    #   ret += pluralize(object.awesome_count, 'awesome')
    # end
    ret += '</div>'
    ret
  end
end
