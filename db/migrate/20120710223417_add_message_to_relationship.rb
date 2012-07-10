class AddMessageToRelationship < ActiveRecord::Migration
  def change
    add_column :relationships, :message, :text
  end
end
