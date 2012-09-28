class AddExternalUrlToVideos < ActiveRecord::Migration
  def change
    add_column :videos, :external_url, :string
  end
end
