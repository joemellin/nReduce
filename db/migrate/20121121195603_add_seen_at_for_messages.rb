class AddSeenAtForMessages < ActiveRecord::Migration
  def change
    add_column :conversation_statuses, :seen_at, :datetime
    add_column :relationships, :seen_by, :string
  end
end
