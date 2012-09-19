class AddCachedTagFields < ActiveRecord::Migration
  def up
    add_column :startups, :cached_industry_list, :string
    add_column :users, :cached_skill_list, :string
    add_column :users, :cached_industry_list, :string

    # Need to reset column info so acts_as_taggable_on adds save_cached_tag_list method
    Startup.reset_column_information
    ActsAsTaggableOn::Taggable::Cache.included(Startup)
    User.reset_column_information
    ActsAsTaggableOn::Taggable::Cache.included(User)

    Startup.all.each do |s|
      s.industry_list
      s.save_cached_tag_list
      s.save(:validate => false)
    end

    User.all.each do |u|
      u.skill_list
      u.industry_list
      u.save_cached_tag_list
      u.save(:validate => false)
    end
  end

  def down
    remove_column :startups, :cached_industry_list
    remove_column :users, :cached_skill_list
    remove_column :users, :cached_industry_list
  end
end