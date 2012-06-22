class CreateInvites < ActiveRecord::Migration
  def change
    create_table :invites do |t|
      t.string :email, :code, :msg
      t.integer :invite_type
      t.datetime :expires_at, :accepted_at
      t.boolean :accepted
      t.references :to, :from, :startup
      t.timestamps
    end

    add_index :invites, :code
  end
end
