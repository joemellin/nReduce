class AddCommentCount < ActiveRecord::Migration
  def change
    add_column :comments, :reply_count, :integer, :default => 0
  end
end
