class CreateScreenshots < ActiveRecord::Migration
  def change
    create_table :screenshots do |t|
      t.string :image, :title
      t.integer :position
      t.references :user, :startup
      t.timestamps
    end
  end
end
