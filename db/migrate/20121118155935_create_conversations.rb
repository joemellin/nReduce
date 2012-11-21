class CreateConversations < ActiveRecord::Migration
  def change
    drop_table :messages

    create_table :messages do |t|
      t.references :from, :conversation
      t.text :content
      t.datetime :created_at
    end

    add_index :messages, [:conversation_id, :created_at], :name => 'messages_conversation_created'

    User.transaction do
      User.all.each{|u| u.email_on << :message; u.save(:validate => false) }
    end

    create_table :conversations do |t|
      t.string :participant_ids
      t.datetime :updated_at
    end
  end
end
