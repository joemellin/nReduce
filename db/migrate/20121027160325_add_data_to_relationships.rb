class AddDataToRelationships < ActiveRecord::Migration
  def up
    add_column :relationships, :initiated, :boolean, :default => false
    add_column :relationships, :removed_at, :datetime

    Relationship.assign_initiated_relationships
  end

  def down
    remove_column :relationships, :initiated
    remove_column :relationships, :removed_at
  end
end
