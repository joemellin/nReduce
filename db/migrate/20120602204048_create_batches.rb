class CreateBatches < ActiveRecord::Migration
  def change
    create_table :batches do |t|

      t.timestamps
    end
  end
end
