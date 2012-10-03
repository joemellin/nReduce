class AddTweetQuestionToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :tweet, :boolean, :default => false
  end
end
