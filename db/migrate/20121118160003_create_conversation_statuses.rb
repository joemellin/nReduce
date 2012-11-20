class CreateConversationStatuses < ActiveRecord::Migration
  def change
    create_table :conversation_statuses do |t|
      t.references :user, :conversation
      t.integer :folder
      t.datetime :read_at
    end

    add_index :conversation_statuses, [:user_id, :read_at, :folder], :name => 'conv_status_user_read_folder'
  end
end