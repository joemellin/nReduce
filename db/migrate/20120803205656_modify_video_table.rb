class ModifyVideoTable < ActiveRecord::Migration
  def up
    remove_column :videos, :video_type
    remove_column :videos, :callback_result
    rename_column :videos, :file_url, :local_file_path
    add_column :videos, :vimeod, :boolean, :default => false
    add_column :videos, :type, :string
  end

  def down
    add_column :videos, :video_type, :integer
    add_column :videos, :callback_results, :text
    rename_column :videos, :local_file_path, :file_url
    remove_column :videos, :vimeod
    remove_column :videos, :type
  end
end
