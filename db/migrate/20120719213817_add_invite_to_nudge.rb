class AddInviteToNudge < ActiveRecord::Migration
  def change
    add_column :nudges, :invite_id, :integer
  end
end
