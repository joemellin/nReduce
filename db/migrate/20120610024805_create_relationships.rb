class CreateRelationships < ActiveRecord::Migration
  def change
    create_table :relationships do |t|
      t.references :startup, :connected_with
      t.integer :status
      t.datetime :created_at, :approved_at, :rejected_at
    end

    add_index :relationships, [:startup_id, :connected_with_id, :status], :name => 'relationship_index', :unique => true
  end
end
