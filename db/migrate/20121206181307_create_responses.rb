class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.text :data, :extra_data
      t.integer :amount_paid, :default => 0
      t.integer :status
      t.datetime :accepted_at, :expired_at, :completed_at
      t.string :rejected_because
      t.boolean :thanked, :default => false
      t.references :request, :user
      t.timestamps
    end

    add_index :responses, :request_id
  end
end