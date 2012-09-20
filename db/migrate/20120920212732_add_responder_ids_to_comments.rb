class AddResponderIdsToComments < ActiveRecord::Migration
  def change
    add_column :comments, :responder_ids, :text
    add_column :comments, :deleted, :boolean, :default => false
  end
end
