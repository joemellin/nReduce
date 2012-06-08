class CreateAuthentications < ActiveRecord::Migration
  def change
    create_table :authentications do |t|
      t.string :provider, :uid, :token, :secret
      t.references :user
      t.timestamps
    end

    add_index :authentications, [:provider, :uid]
  end
end