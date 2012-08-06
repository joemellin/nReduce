class AddEmailedAtToInvites < ActiveRecord::Migration
  def change
    add_column :invites, :emailed_at, :datetime
  end
end
