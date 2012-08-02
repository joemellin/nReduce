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
  after_destroy :update_cache_and_count
  
  validates_presence_of :content
  validates_presence_of :user_id
  validates_presence_of :checkin_id

  scope :ordered, order('created_at DESC')

  protected

  def notify_users_and_update_count
    update_cache_and_count
    parent_comment = self.parent
    user_ids = [self.user.id]
    # Notify all users up in the comment reply chain
    while !parent_comment.blank?
      # Notify person that this comment was a reply to - but not if they were above in the comments
      unless user_ids.include?(parent_comment.user_id)
        Notification.create_for_comment_reply(self, parent_comment.user) 
        user_ids << parent_comment.user_id
      end
      parent_comment = parent_comment.parent
    end
    # Notify all team members who are on team with checkin of new comment
    Notification.create_for_new_comment(self) unless parent_comment and (parent_comment.user_id == self.user_id)
  end

  def update_cache_and_count
    # delete cache of checkin ids this user has commented on
    Cache.delete(['cids', self.user])
    # update checkin comment count
    self.checkin.update_comments_count
  end
end
