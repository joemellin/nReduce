class SetStartupsAsConnectedAndAddActivatedAt < ActiveRecord::Migration
  def up
    add_column :startups, :activated_at, :datetime
    Startup.transaction do
      Startup.all.each{|s| s.setup << :connections; s.activated_at = s.created_at; s.save(:validate => false) }
    end
  end

  def down
    remove_column :startups, :activated_at
  end
end
