class CreateNudges < ActiveRecord::Migration
  def change
    create_table :nudges do |t|
      t.references :from, :startup
      t.datetime :seen_at
      t.timestamps
    end
  end
end
