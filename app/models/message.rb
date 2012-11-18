class Message < ActiveRecord::Base
  belongs_to :from, :class_name => 'User'

  attr_accessible :from, :from_id, :content

end


