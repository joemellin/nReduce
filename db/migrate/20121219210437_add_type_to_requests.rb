class AddTypeToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :type, :string
    add_column :responses, :tip, :integer, :default => 0
  end
end
