module AwesomesHelper
  def render_awesome_button(object)
    return '' unless user_signed_in?
    return '' if object.user_id == current_user.id
    label = Awesome.label_for_type(object.class.to_s)
    awesome_id = current_user.awesome_id_for_object(object)
    ret = '<div id=' + Awesome.unique_id_for_object(object) + '>'
    if awesome_id.blank?
      ret += link_to("<i class=\"icon-thumbs-up icon\"></i> #{label}".html_safe, "/awesomes/?awsm_type=#{object.class.to_s}&awsm_id=#{object.id}", :remote => true, :method => :post, :class => 'btn')
    else
      ret += link_to("<i class=\"icon-thumbs-up icon-white\"></i> #{label}".html_safe, awesome_path(:id => awesome_id), :remote => true, :method => :delete, :class => 'btn btn-success')
    end
    # if object.awesome_count > 0
    #   ret += pluralize(object.awesome_count, 'awesome')
    # end
    ret += '</div>'
  end
end
