class AddValueToRating < ActiveRecord::Migration
  def change
    add_column :ratings, :value, :integer
  end
end
