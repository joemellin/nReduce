class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :checkin
  has_one :startup, :through => :checkin
  has_many :awesomes, :as => :awsm
  has_many :notifications, :as => :attachable
  
  attr_accessible :content, :checkin_id

  after_create :notify_users
  
  validates_presence_of :content
  validates_presence_of :user_id
  validates_presence_of :checkin_id

  scope :ordered, order('created_at DESC')

  protected

  def notify_users
    Notification.create_for_new_comment(self)
  end
end
