class RenameRatingsColumnToUser < ActiveRecord::Migration
  def up
    rename_column :ratings, :investor_id, :user_id
  end

  def down
    rename_column :ratings, :user_id, :investor_id
  end
end
