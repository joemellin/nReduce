class RelationshipsPolymorphic < ActiveRecord::Migration
  def up
  	rename_column :relationships, :startup_id, :entity_id
  	add_column :relationships, :entity_type, :string, :length => 10 # limit length for performance
  	add_column :relationships, :connected_with_type, :string, :length => 10

  	remove_index :relationships, :name => 'relationship_index'
  	add_index :relationships, [:entity_id, :entity_type, :status], :name => 'relationship_index'
  	Relationship.all.each do |r|
  		r.entity_type = 'Startup'
  		r.connected_with_type = 'Startup'
  		r.save
  	end
  end

  def down
  	rename_column :relationships, :entity_id, :startup_id
  	remove_column :relationships, :entity_type
  	remove_column :relationships, :connected_with_type

  	remove_index :relationships, :name => 'relationship_index'
  	add_index :relationships, [:startup_id, :connected_with_id, :status], :name => 'relationship_index', :unique => true
  end
end
