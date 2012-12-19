class AddTypeToRequests < ActiveRecord::Migration
  def up
    add_column :requests, :type, :string
    add_column :responses, :tip, :integer, :default => 0
    remove_column :requests, :request_type

    # Update all previous requests
    Request.all.each{|r| r.type ||= 'RetweetRequest'; r.save(:validate => false) }
  end

  def down
    remove_column :requests, :type
    remove_column :responses, :tip, :integer
    add_column :requests, :request_type, :integer

    Request.all.each{|r| r.request_type = [:retweet]; r.save(:validate => false) }
  end
end
