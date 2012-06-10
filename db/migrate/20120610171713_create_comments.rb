class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :content
      t.references :user, :checkin
      t.timestamps
    end

    add_index :comments, :checkin_id
  end
end
