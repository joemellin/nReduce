class SetStartupsAsConnected < ActiveRecord::Migration
  def up
    Startup.transaction do
      Startup.all.each{|s| s.setup << :connections; s.save(:validate => false) }
    end
  end

  def down
  end
end
