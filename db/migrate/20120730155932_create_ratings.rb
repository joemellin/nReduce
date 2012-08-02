class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer :investor_id
      t.integer :startup_id
      t.boolean :interested
      t.integer :feedback
      t.text :explanation

      t.timestamps
    end
  end
end
