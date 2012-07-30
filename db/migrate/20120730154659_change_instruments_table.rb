class ChangeInstrumentsTable < ActiveRecord::Migration
  def up
    remove_column :instruments, :data
    remove_column :instruments, :inst_type
    add_column :instruments, :startup_id, :integer
    add_column :instruments, :name, :string
    add_column :instruments, :description, :text
  end

  def down
    add_column :instruments, :data, :string
    add_column :instruments, :inst_type, :integer
    remove_column :instruments, :startup_id
    remove_column :instruments, :name
    remove_column :instruments, :description
  end
end
