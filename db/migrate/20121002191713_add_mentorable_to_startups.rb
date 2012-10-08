class AddMentorableToStartups < ActiveRecord::Migration
  def change
    add_column :startups, :mentorable, :boolean, :default => false
  end
end
