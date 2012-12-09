class CreateAccountTransfers < ActiveRecord::Migration
  def change
    create_table :account_transfers do |t|
      t.string :attachable_type, :from_account_type, :to_account_type
      t.integer :attachable_id, :amount
      t.references :from_account, :to_account 
      t.timestamps
    end

    add_index :account_transfers, [:from_account_id, :to_account_id]
  end
end
