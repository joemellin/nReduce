class AddStartupToConversation < ActiveRecord::Migration
  def change
    add_column :conversations, :team_to_team, :boolean, :default => false
  end
end
