class AddConnectedToRating < ActiveRecord::Migration
  def change
    add_column :ratings, :connected, :boolean
  end
end
