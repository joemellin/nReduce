class AddFieldsToStartup < ActiveRecord::Migration
  def change
    add_column :startups, :business_model, :text
    add_column :startups, :founding_date, :date
    add_column :startups, :market_size, :string
  end
end
