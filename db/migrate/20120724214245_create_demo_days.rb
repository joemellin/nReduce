class CreateDemoDays < ActiveRecord::Migration
  def change
    create_table :demo_days do |t|
      t.string :name
      t.text :description
      t.date :day
      t.timestamps
    end

    DemoDay.create(:name => 'nReduce September 5th Demo Day', :day => Date.parse('2012-09-05'))
  end
end
