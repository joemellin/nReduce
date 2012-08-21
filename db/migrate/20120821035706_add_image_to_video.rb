class AddImageToVideo < ActiveRecord::Migration
  def change
    add_column :videos, :image, :string
  end
end
