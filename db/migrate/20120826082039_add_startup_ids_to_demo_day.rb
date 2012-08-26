class AddStartupIdsToDemoDay < ActiveRecord::Migration
  def change
    add_column :demo_days, :startup_ids, :string
  end
end
