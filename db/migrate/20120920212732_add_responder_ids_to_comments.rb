class AddResponderIdsToComments < ActiveRecord::Migration
  def up
    add_column :comments, :responder_ids, :text
    add_column :comments, :deleted, :boolean, :default => false
    add_column :comments, :startup_id, :integer
    add_column :comments, :original_id, :integer

    remove_index :comments, :checkin_id
    remove_index :comments, :ancestry
    add_index :comments, [:checkin_id, :ancestry]
    add_index :comments, [:startup_id, :created_at]

    # Save comments to populate with startup id
    Comment.all.each do |c|
      c.save
    end
  end

  def down
    remove_column :comments, :responder_ids
    remove_column :comments, :deleted
    remove_column :comments, :startup_id
    remove_column :comments, :original_id

    add_index :comments, :checkin_id
    add_index :comments, :ancestry
    remove_index :comments, [:checkin_id, :ancestry]
    remove_index :comments, [:startup_id, :created_at]
  end
end
