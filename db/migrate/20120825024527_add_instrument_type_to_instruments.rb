class AddInstrumentTypeToInstruments < ActiveRecord::Migration
  def up
    add_column :instruments, :instrument_type_id, :integer
    add_index :instruments, :startup_id
  end

  def down
    remove_index :instruments, :startup_id
  end
end
