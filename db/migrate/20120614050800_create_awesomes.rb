class CreateAwesomes < ActiveRecord::Migration
  def change
    create_table :awesomes do |t|
      t.string :awsm_type
      t.integer :awsm_id
      t.references :user
      t.timestamps
    end

    add_index :awesomes, [:user_id, :awsm_type, :awsm_id], :name => 'awesomes_index', :unique => true
    add_column :checkins, :awesome_count, :integer, :default => 0
    add_column :comments, :awesome_count, :integer, :default => 0
  end
end
