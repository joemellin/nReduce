class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :subject
      t.integer :folder, :default => 1
      t.text :body
      t.datetime :sent_at, :read_at
      t.references :sender, :recipient
    end

    add_index :messages, [:recipient_id, :folder, :read_at], :name => 'messages_comp_index'
  end
end
