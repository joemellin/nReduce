class RemoveDashesFromTags < ActiveRecord::Migration
  def up
    ActsAsTaggableOn::Tag.all.each do |t|
      t.name = t.name.gsub('-', ' ')
      t.save
    end
  end

  def down
    ActsAsTaggableOn::Tag.all.each do |t|
      t.name = t.name.gsub(' ', '-')
      t.save
    end
  end
end
