class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.string :data, :from_sid, :to_sid
      t.boolean :confirmed
      t.integer :status, :scheduled_state, :duration, :from_status, :to_status, :from_rating, :to_rating
      t.datetime :scheduled_at
      t.references :from, :to
      t.timestamps
    end

    add_index :calls, [:from_id, :created_at]
  end
end
