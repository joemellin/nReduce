class CreateUserActions < ActiveRecord::Migration
  def change
    create_table :user_actions do |t|
      t.integer :action
      t.string :url_path, :ip, :browser
      t.text :data
      t.float :time_taken
      t.references :user
      t.references :attachable, :polymorphic => true
      t.timestamps
    end
  end
end