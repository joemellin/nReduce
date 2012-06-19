class AddFieldsToUser < ActiveRecord::Migration
  def change
    add_column :users, :one_liner, :string
    add_column :users, :bio, :text
    add_column :users, :github_url, :string
    add_column :users, :dribbble_url, :string
    add_column :users, :blog_url, :string
  end
end
