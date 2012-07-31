class AddPendingAtToRelationships < ActiveRecord::Migration
  def change
    add_column :relationships, :pending_at, :datetime

    # Update all relationships to have pending at time
    Relationship.all.each do |r|
      r.pending_at = r.created_at unless r.suggested? or r.passed?
      r.save(:validate => false)
    end
  end
end
