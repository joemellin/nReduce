module AwesomesHelper
  def render_awesome_button(object)
    return '' unless user_signed_in?
    awesome = current_user.awesome_for_object(object) || Awesome.new(:awsm => object)
    ret = '<div id=' + awesome.unique_id + '>'
    if awesome.new_record?
      ret += link_to('<i class="icon-thumbs-up icon"></i> Awesome'.html_safe, "/awesomes/?awsm_type=#{object.class.to_s}&awsm_id=#{object.id}", :remote => true, :method => :post, :class => 'btn')
    else
      ret += link_to('<i class="icon-thumbs-up icon-white"></i> Awesome'.html_safe, awesome, :remote => true, :method => :delete, :class => 'btn btn-success')
    end
    # if object.awesome_count > 0
    #   ret += pluralize(object.awesome_count, 'awesome')
    # end
    ret += '</div>'
  end
end
