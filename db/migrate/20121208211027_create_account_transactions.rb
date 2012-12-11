class CreateAccountTransactions < ActiveRecord::Migration
  def change
    create_table :account_transactions do |t|
      t.string :attachable_type, :from_account_type, :to_account_type
      t.integer :attachable_id, :amount, :transaction_type
      t.references :from_account, :to_account
      t.timestamps
    end

    add_index :account_transactions, [:from_account_id, :to_account_id]
  end
end
