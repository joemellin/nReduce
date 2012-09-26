class Comment < ActiveRecord::Base
  has_ancestry
  belongs_to :user
  belongs_to :checkin
  belongs_to :parent, :class_name => 'Comment'
  belongs_to :original, :class_name => 'Comment'
  has_many :reposts, :class_name => 'Comment', :foreign_key => 'original_id'
  has_one :startup, :through => :checkin
  has_many :awesomes, :as => :awsm
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable
  
  attr_accessible :content, :checkin_id, :parent_id, :parent, :original_id, :original

  before_save :assign_startup
  after_create :notify_users_and_update_count
  after_destroy :update_cache_and_count

  serialize :responder_ids, Array
  
  validates_presence_of :content
  validates_presence_of :user_id
  #validates_presence_of :checkin_id

  scope :posts, where('checkin_id IS NULL AND ancestry IS NULL').order('created_at DESC')
  scope :ordered, order('created_at DESC')

  # Finds the hottest post 24 hours ago until time
  def self.hottest_post_for_time(time)
    beginning_of_day = time - 24.hours
    # Find posts created less than three days ago, with activity in the last 24 hours
    active_posts = Comment.posts.where(['created_at > ? AND updated_at >= ? AND updated_at <= ?', beginning_of_day - 3.days, beginning_of_day, time])
    # Sort by posts with the most activity (technically doesn't know what day they responded)
    hottest_post = active_posts.sort{|a,b| a.responder_ids.size <=> b.responder_ids.size }.reverse.last
    # Only return post if anyone actually responded
    return hottest_post if hottest_post.present? && hottest_post.responder_ids.present?
    return nil
  end

  # Posts this comment (like re-tweeting) from a new user. It will save the originator and then the post is also
  def repost_by(user)
    c = Comment.new
    c.content = self.content
    c.original = self
    c.user = user
    c.original.save if c.save # update cache on responders
    c
  end

  # All people who commented or liked this post
  def responders
    return [] if self.responder_ids.blank?
    User.find(self.responder_ids)
  end

  def responder_ids
    self['responder_ids'].blank? ? [] : self['responder_ids']
  end

  # This comment is for a checkin
  def for_checkin?
    self.checkin_id.present?
  end

  # This is a comment on a post
  def for_post?
    self.checkin_id.blank?
  end

  # This is the original (root) post
  def original_post?
    self.ancestry.blank? && self.checkin_id.blank?
  end

  # Queries who responded to this post and updates cached count and ids
  def update_responders
    self.responder_ids = (self.responder_ids + self.children.map{|c| c.user_id } + self.awesomes.map{|a| a.user_id } + self.reposts.map{|c| c.user_id }).uniq
    self.responder_ids -= [self.user_id] # don't include author
    self.save
  end

  protected

  def assign_startup
    unless self.user.startup_id.blank?
      self.startup_id = self.user.startup_id
    end
    true
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
