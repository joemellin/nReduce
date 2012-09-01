class Question < ActiveRecord::Base
  belongs_to :user
  belongs_to :startup

  serialize :supporter_ids

  attr_accessible :content, :startup, :startup_id

  validates :user_id, :startup_id, :presence => true
  validates :content, :length => { :maximum => 100, :minimum => 10 }

  after_create :tweet_question
  before_create :update_followers_and_attendees

  scope :unanswered, where('answered_at IS NULL')
  scope :ordered, order('followers_count DESC')

  attr_accessor :unseen

  def unseen?
    self.unseen == true
  end

  def is_supporter?(user)
    return true if self.user_id == user.id
    return true if self.supporter_ids.include?(user.id) if self.supporter_ids.present?
    return false
  end

  # Returns an array of all the users who support this question
  def supporters(dont_include_creator = false)
    ids = []
    ids << self.user_id unless dont_include_creator
    ids += self.supporter_ids if self.supporter_ids.present?
    return [] if ids.blank?
    User.find(ids)
  end

  def add_supporter!(user, dont_tweet = false)
    # Return true if already a supporter
    return true if self.is_supporter?(user)
    self.supporter_ids ||= []
    # Add supporter id
    self.supporter_ids << user.id
    # Retweet from supporter's account
    if !dont_tweet && self.tweet_id.present?
      tw = user.twitter_client
      self.followers_count += user.followers_count if user.followers_count.present?
      tw.retweet(self.tweet_id) if Rails.env.production?
    end
    if save
      self.add_attendee_to_demo_day(self.user)
    else
      false
    end
  end

  def remove_supporter!(user)
    self.supporter_ids.delete(user.id) unless self.supporter_ids.blank?
    save
  end

  def answer!
    self.answered_at = Time.now
    self.save
  end

  def tweet_content
    "#{self.content.first(100)} #demoday http://nreduce.com/d/#{DemoDay.next_or_current.index_of(self.startup)}"
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

  def add_attendee_to_demo_day(attendee)
    dd = DemoDay.next_or_current
    dd.add_attendee!(attendee, true) if dd.present?
  end

  def update_followers_and_attendees
    self.followers_count = self.user.followers_count if self.user.followers_count.present?
    self.add_attendee_to_demo_day(self.user)
  end
end