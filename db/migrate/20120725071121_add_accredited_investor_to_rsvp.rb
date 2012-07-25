class AddAccreditedInvestorToRsvp < ActiveRecord::Migration
  def change
    add_column :rsvps, :accredited, :boolean
  end
end
