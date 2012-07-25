class CreateRsvps < ActiveRecord::Migration
  def change
    create_table :rsvps do |t|
      t.string :email, :message
      t.references :user, :startup, :demo_day
      t.timestamps
    end
  end
end
