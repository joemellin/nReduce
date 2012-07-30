class CreateSlideDecks < ActiveRecord::Migration
  def change
    create_table :slide_decks do |t|
      t.integer :startup_id
      t.text :slides
      t.string :title

      t.timestamps
    end
  end
end
