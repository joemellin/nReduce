class CreateConversations < ActiveRecord::Migration
  def change
    drop_table :messages

    create_table :messages do |t|
      t.references :from, :conversation
      t.text :content
      t.datetime :created_at
    end

    add_index :messages, [:conversation_id, :created_at], :name => 'messages_conversation_created'

    create_table :conversations do |t|
      t.string :participant_ids
      t.datetime :updated_at
    end
  end
end
