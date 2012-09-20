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

  serialize :responder_ids
  
  validates_presence_of :content
  validates_presence_of :user_id
  #validates_presence_of :checkin_id

  scope :posts, where('checkin_id IS NULL AND ancestry IS NULL').order('created_at DESC')
  scope :ordered, order('created_at DESC')

  def responders
    return [] if self.responder_ids.blank?
    User.find(self.responder_ids)
  end

  def for_checkin?
    self.checkin_id.present?
  end

  def for_post?
    self.checkin_id.blank?
  end

  def original_post?
    self.ancestry.blank? && self.checkin_id.blank?
  end

  protected

  def update_responders
    self.responder_ids ||= []
    self.responder_ids = (self.responder_ids + self.children.map{|c| c.user_id } + self.awesomes.map{|a| a.user_id }).uniq
    self.responder_ids -= [self.user_id]
    self.save
  end

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
    if self.for_checkin?
      # delete cache of checkin ids this user has commented on
      Cache.delete(['cids', self.user])
      # update checkin comment count
      self.checkin.update_comments_count
    elsif self.for_post?
      self.root.update_responders unless self.root == self
    end
  end
end
