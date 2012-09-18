class AddIndexToVideoAndQuestions < ActiveRecord::Migration
  def change
    add_index :questions, [:startup_id, :answered_at, :updated_at], :name => 'startup_answered_updated', :unique => true
    add_index :videos, [:external_id, :type], :unique => true
  end
end
