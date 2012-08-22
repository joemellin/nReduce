class ChangeFieldsOnRating < ActiveRecord::Migration
  def up
    rename_column :ratings, :value, :contact_in
    add_column :ratings, :weakest_element, :integer
  end

  def down
    rename_column :ratings, :contact_in, :value
    remove_column :ratings, :weakest_element
  end
end
