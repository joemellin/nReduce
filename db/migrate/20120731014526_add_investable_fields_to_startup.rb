class AddInvestableFieldsToStartup < ActiveRecord::Migration
  def change
    add_column :startups, :investable, :boolean, :default => false
  end
end
