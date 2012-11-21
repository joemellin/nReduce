class AddLastMessageToConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :latest_message_id, :integer
  end
end
