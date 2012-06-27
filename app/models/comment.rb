class Comment < ActiveRecord::Base
  has_ancestry
  belongs_to :user
  belongs_to :checkin
  belongs_to :parent, :class_name => 'Comment'
  has_one :startup, :through => :checkin
  has_many :awesomes, :as => :awsm
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable
  
  attr_accessible :content, :checkin_id, :parent_id

  after_create :notify_users_and_update_count
  after_destroy :reset_user_comment_cache
  
  validates_presence_of :content
  validates_presence_of :user_id
  validates_presence_of :checkin_id

  scope :ordered, order('created_at DESC')

  protected

  def notify_users_and_update_count
    reset_user_comment_cache
    parent_comment = self.parent
    # Notify person that this comment was a reply to
    Notification.create_for_comment_reply(self, parent_comment.user) if !parent_comment.blank?
    # Notify all team members who are on team with checkin of new comment
    Notification.create_for_new_comment(self) unless parent_comment and (parent_comment.user_id == self.user_id)
    self.checkin.update_comments_count
  end

  def reset_user_comment_cache
    # delete cache of checkin ids this user has commented on
    Cache.delete(['cids', self.user])
  end
end
