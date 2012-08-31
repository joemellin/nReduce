class Question < ActiveRecord::Base
  belongs_to :user
  belongs_to :startup

  serialize :supporter_ids

  attr_accessible :content, :startup, :startup_id

  validates :user_id, :startup_id, :presence => true
  validates :content, :length => { :maximum => 100 }

  after_create :tweet_question
  before_create :update_user_followers_count

  scope :unanswered, where('answered_at IS NULL')
  scope :ordered, order('followers_count DESC')

  def is_supporter?(user)
    return true if self.user_id == user.id
    return true if self.supporter_ids.include?(user.id) if self.supporter_ids.present?
    return false
  end

  # Returns an array of all the users who support this question
  def supporters(dont_include_creator = false)
    ids = [self.user_id]
    ids += self.supporter_ids if self.supporter_ids.present?
    User.find(ids)
  end

  def add_supporter!(user, dont_tweet = false)
    # Return true if already a supporter
    return true if self.is_supporter?(user)
    self.supporter_ids ||= []
    # Add supporter id
    self.supporter_ids << user.id
    # Retweet from supporter's account
    if self.tweet_id.present?
      tw = user.twitter_client
      self.followers_count += user.followers_count if user.followers_count.present?
      tw.retweet(self.tweet_id) if Rails.env.production?
    end
    save
  end

  def remove_supporter!(user)
    self.supporter_ids.delete(user.id) unless self.supporter_ids.blank?
    save
  end

  def answered!
    self.answered_at = Time.now
    self.save
  end

  def tweet_content
    "#{self.content.first(90)} #nReduce http://demoday.nreduce.com/#{self.id}"
  end

  # Tweets question from creator's account
  def tweet_question
    return true unless Rails.env.production?
    tw = self.user.twitter_client
    return false if tw.blank?
    tweet = tw.update(self.tweet_content)
    # Save tweet id
    if tweet.present?
      self.tweet_id = tweet.id 
      self.save
    end
  end

  protected

  def update_user_followers_count
    self.followers_count = self.user.followers_count if self.user.followers_count.present?
  end
end