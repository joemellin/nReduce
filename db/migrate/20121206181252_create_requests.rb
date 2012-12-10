class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string :title
      t.integer :request_type, :price
      t.integer :num, :default => 0
      t.text :data, :extra_data
      t.references :startup, :user
      t.timestamps
    end

    add_index :requests, :num
  end
end