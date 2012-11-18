class CreateAbTests < ActiveRecord::Migration
  def change
    create_table :ab_tests do |t|
      t.string :name, :option_a, :option_b
      t.datetime :starts_at, :ends_at
      t.timestamps
    end
  end
end
