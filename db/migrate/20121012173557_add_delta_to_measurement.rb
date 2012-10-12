class AddDeltaToMeasurement < ActiveRecord::Migration
  def change
    add_column :measurements, :delta, :float
  end
end
