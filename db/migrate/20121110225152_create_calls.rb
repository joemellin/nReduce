class CreateCalls < ActiveRecord::Migration
  def change
    create_table :calls do |t|
      t.string :data
      t.integer :status, :scheduled_state, :duration, :from_rating, :to_rating
      t.datetime :scheduled_at
      t.references :from_user, :to_user
      t.timestamps
    end

    add_index :calls, [:from_user_id, :created_at]
  end
end
