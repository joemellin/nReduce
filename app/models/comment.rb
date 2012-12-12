class Comment < ActiveRecord::Base
  has_ancestry
  belongs_to :user
  belongs_to :checkin
  belongs_to :parent, :class_name => 'Comment'
  belongs_to :original, :class_name => 'Comment'
  has_many :reposts, :class_name => 'Comment', :foreign_key => 'original_id', :dependent => :destroy
  has_many :awesomes, :as => :awsm, :dependent => :destroy
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable
  
  attr_accessible :content, :checkin_id, :parent_id, :parent, :original_id, :original, :deleted

  before_save :assign_startup
  after_create :notify_users_and_update_count
  after_destroy :update_cache_and_count

  serialize :responder_ids, Array
  
  validates_presence_of :content
  validates_presence_of :user_id
  #validates_presence_of :checkin_id

  scope :posts, where('checkin_id IS NULL AND ancestry IS NULL').order('created_at DESC')
  scope :ordered, order('created_at DESC')
  scope :deleted, where(:deleted => true)
  scope :not_deleted, where(:deleted => false)

  def self.comments_per_checkin(checkin_ids = [])
    Comment.where(:checkin_id => checkin_ids).group(:checkin_id).count
  end

  # Finds the hottest post 24 hours ago until time
  def self.hottest_post
    comment_id = Comment.hottest_post_id
    Comment.find(comment_id) if comment_id.present?
  end

  def self.hottest_post_id
    Cache.get('hottest_post', 1.hour, true){
      time = Time.now
      beginning_of_day = time - 24.hours
      # Find posts created less than three days ago, with activity in the last 24 hours
      active_posts = Comment.posts.where(['created_at > ? AND updated_at >= ? AND updated_at <= ?', beginning_of_day - 3.days, time - 6.hours, time])
      # Sort by posts with the most activity (technically doesn't know what day they responded)
      hottest_post = active_posts.sort{|a,b| a.responder_ids.flatten.size <=> b.responder_ids.flatten.size }.last
      # Only return post if anyone actually responded
      if hottest_post.present? && hottest_post.responder_ids.present?
        hottest_post.id 
      else
        nil
      end
    }
  end

  # Custom logic to select from checkin or post
  def startup
    return Startup.where(:id => self.startup_id) if self.startup_id.present?
    return self.checkin.startup if self.checkin_id.present
    nil
  end

  # Need custom logic or else it also selects itself
  def reposts
    Comment.where(:original_id => self.id).where(['id != ?', self.id])
  end

  def can_be_viewed_by?(user)
    # Can only be viewed by people with a startup
    return false if user.startup_id.blank?
    # Anyone can view the hottest post
    return true if Comment.hottest_post_id.to_i == self.id
    startup_ids = user.startup.second_degree_connection_ids
    # Return true if one of this person's connections created this comment
    return true if startup_ids.include?(self.startup_id)
    # Return true if this was reposted by one of their connections
    reposted_by_startup_ids = self.reposts.map{|r| r.startup_id }
    # Check if intersection of both arrays is not empty
    return true if !(startup_ids & reposted_by_startup_ids).empty?
    false
  end

  # Posts this comment (like re-tweeting) from a new user. It will save the originator and then the post is also
  def repost_by(user)
    c = Comment.new
    c.content = self.content
    # if this was a repost itself, use this post's original
    c.original = self.original ? self.original : self
    c.user = user
    c.original.save if c.save # update cache on responders
    c
  end

  # All people who commented or liked this post
  def responders
    return [] if self.responder_ids.blank?
    User.find(self.responder_ids.flatten - [self.user_id]) # don't include author
  end

  def commented_by?(user)
    self.responder_ids.present? && self.responder_ids[0].include?(user.id)
  end

  def reposted_by?(user)
    self.responder_ids.present? && self.responder_ids[1].include?(user.id)
  end

  def liked_by?(user)
    self.responder_ids.present? && self.responder_ids[2].include?(user.id)
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

  def is_repost?
    self.original_id.present?
  end

  # Queries who responded to this post and updates cached count and ids
  def update_responders
    return true unless self.original_post?
    children = self.descendants
    awesomes = self.awesomes
    # Save as array with comment user ids, then repost user ids, then awesome user ids
    self.responder_ids = [children.map{|c| c.user_id }, self.reposts.map{|c| c.user_id }, awesomes.map{|a| a.user_id }]
    self.responder_ids = [] if self.responder_ids.present? && self.responder_ids[0].blank? && self.responder_ids[1].blank? && self.responder_ids[2].blank?
    self.reply_count = children.size
    self.awesome_count = awesomes.size
    self.save
  end

  # If this is a root post then we can delete it
  def safe_destroy
    if self.is_root? && self.original_post?
      Comment.transaction do
        self.descendants.each{|c| c.destroy }
      end
      self.destroy
    else
      self.update_attribute('deleted', true)
    end
  end

  protected

  def assign_startup
    if self.user.present? && self.user.startup.present?
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
    Notification.create_for_new_comment(self) unless self.original_post? || (parent_comment && (parent_comment.user_id == self.user_id))
    # Assign original comment id for posts so we can de-duplicate shared posts
    self.original_id = self.id if self.for_post? && self.original_id.blank?
    self.save
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
