class CreateMeasurements < ActiveRecord::Migration
  def change
    create_table :measurements do |t|
      t.integer :instrument_id
      t.float :value

      t.timestamps
    end
  end
end
