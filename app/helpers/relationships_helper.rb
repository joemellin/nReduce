module RelationshipsHelper
	def relationship_button_for(entity, connected_with, relationship = nil)
		capture do
			content_tag(:div, :class => "#{connected_with.class}_#{connected_with.id}_relationship relationship") do
				if (!relationship.blank? and relationship.approved?) or entity.connected_to?(connected_with)
					if !relationship.blank?
						link_to '<i class="icon icon-remove"></i> Remove from Group'.html_safe, reject_relationship_path(:id => relationship.id), :method => :destroy, :class => 'btn', :confirm => "Are you sure you want to remove #{connected_with.name} as a connection?"
					else
						link_to 'View Profile', connected_with, :class => 'btn btn-large', :style => 'margin-bottom: 12px'
					end
				elsif !relationship.blank? and relationship.pending?
					# This is the person being requested
					if relationship.connected_with == entity
						concat link_to '<i class="icon-remove"></i> Ignore'.html_safe, reject_relationship_path(relationship), :class => 'btn btn-large', :method => :post
						concat '&nbsp;&nbsp;'.html_safe
						concat link_to '<i class="icon-ok icon-white"></i> Approve Request'.html_safe, approve_relationship_path(relationship), :class => 'btn btn-large btn-success', :method => :post
					else # This is the person who initiated
						link_to '<i class="icon-remove icon-white"></i> Remove Request'.html_safe, reject_relationship_path(relationship), :class => 'btn btn-large btn-danger', :method => :post
					end
				elsif !relationship.blank? and relationship.suggested?
					concat link_to '<i class="icon-refresh"></i> Pass'.html_safe, reject_relationship_path(relationship), :class => 'btn btn-large', :method => :post
					concat '&nbsp;&nbsp;'.html_safe
					concat link_to '<i class="icon-ok icon-white"></i> Add Team'.html_safe, approve_relationship_path(relationship), :class => 'btn btn-large btn-success', :method => :post
				elsif user_signed_in? # and Relationship.can_connect?(entity, connected_with)
					form_id = "new_relationship_#{connected_with.obj_str}"
					concat link_to((connected_with.is_a?(Startup) ? 'Invite to Group' : 'Connect'), '#', :onclick => "$('##{form_id}').show(); return false;", :class => 'btn btn-large btn-info')
					concat content_tag(:div, :id => 'invite_team', :class => 'modal hide') do
						concat content_tag(:div, :class => 'modal-header') do
							concat content_tag('button', :class => 'close', :type => 'button', 'data-dismiss' => 'modal') do
								'x'
							end
							concat content_tag('h3', 'Invite a Startup')
						end
						concat content_tag(:div, :class => 'modal-body') do
							concat form_for Relationship.new(:entity => entity, :connected_with => connected_with), :remote => true, :html => {:id => form_id} do |f|
								concat f.hidden_field :entity_id
								concat f.hidden_field :entity_type
								concat f.hidden_field :connected_with_id
								concat f.hidden_field :connected_with_type
								concat f.label :message, "Why you think they are a good match for your startup?"
								concat f.text_area :message
								concat f.submit (connected_with.is_a?(Startup) ? 'Invite to Group' : 'Connect')
							end
						end
					end
				end
			end
		end
	end
end


