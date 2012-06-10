class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :checkin
  has_one :startup, :through => :checkin
  
  attr_accessible :content, :checkin_id
  
  validates_presence_of :content
  validates_presence_of :user_id
  validates_presence_of :checkin_id

  scope :ordered, order('created_at DESC')
end
