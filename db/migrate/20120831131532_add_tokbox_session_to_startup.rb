class AddTokboxSessionToStartup < ActiveRecord::Migration
  def change
    add_column :startups, :tokbox_session_id, :string
  end
end
