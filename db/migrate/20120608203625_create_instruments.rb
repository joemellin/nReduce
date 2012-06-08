class CreateInstruments < ActiveRecord::Migration
  def change
    create_table :instruments do |t|
      t.string :data
      t.integer :inst_type
      t.timestamps
    end
  end
end
