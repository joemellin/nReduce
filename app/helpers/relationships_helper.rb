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
				elsif user_signed_in? # and Relationship.can_connect?(entity, connected_with)
					form_for Relationship.new(:entity => entity, :connected_with => connected_with), :remote => true do |f|
						concat f.hidden_field :entity_id
						concat f.hidden_field :entity_type
						concat f.hidden_field :connected_with_id
						concat f.hidden_field :connected_with_type
						concat f.submit (connected_with.is_a?(Startup) ? 'Invite to Group' : 'Connect'), :class => 'btn btn-large btn-info'
					end
				end
			end
		end
	end
end