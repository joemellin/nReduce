class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.string :stripe_id
      t.float :amount
      t.integer :num_helpfuls, :status
      t.references :account, :user, :account_transaction
      t.timestamps
    end

    add_index :payments, :account_id
    add_column :accounts, :stripe_customer_id, :string
  end
end
