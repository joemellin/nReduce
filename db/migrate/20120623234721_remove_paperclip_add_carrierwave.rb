class RemovePaperclipAddCarrierwave < ActiveRecord::Migration
  def up
    remove_column :startups, :logo_file_name
    remove_column :startups, :logo_content_type
    remove_column :startups, :logo_file_size
    remove_column :startups, :logo_updated_at
    remove_column :users, :pic_file_name
    remove_column :users, :pic_content_type
    remove_column :users, :pic_file_size
    remove_column :users, :pic_updated_at
    add_column :startups, :logo, :string
    add_column :users, :pic, :string
  end

  def down
    add_column :startups, :logo_file_name, :string
    add_column :startups, :logo_content_type, :string
    add_column :startups, :logo_file_size, :integer
    add_column :startups, :logo_updated_at, :datetime
    add_column :users, :pic_file_name, :string
    add_column :users, :pic_content_type, :string
    add_column :users, :pic_file_size, :integer
    add_column :users, :pic_updated_at, :datetime
    remove_column :users, :pic
    remove_column :startups, :logo
  end
end
