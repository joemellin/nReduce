class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.string :content, :tweet_id
      t.text :supporter_ids
      t.integer :followers_count, :default => 0
      t.timestamp :answered_at
      t.references :startup, :user
      t.timestamps
    end
  
    add_column :users, :followers_count, :integer
  end
end
