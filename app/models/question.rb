class Question < ActiveRecord::Base
  belongs_to :user
  belongs_to :startup

  serialize :supporter_ids

  attr_accessible :content, :startup, :startup_id

  after_create :tweet_question

  # Returns an array of all the users who support this question
  def supporters(dont_include_creator = false)
    ids = [self.user_id]
    ids += self.supporter_ids if self.supporter_ids.present?
    User.find(ids)
  end

  def add_supporter!(user, dont_tweet = false)
    self.supporter_ids ||= []
    self.supporter_ids << user.id
    if self.tweet_id.present?
      tw = user.twitter_client
      self.followers_count += user.followers_count
      tw.update(self.tweet_content)
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
    tw = self.user.twitter_client
    return nil if tw.blank?
    tweet = tw.update(self.tweet_content)
    # Save tweet id
    if tweet.present?
      self.tweet_id = tweet.id 
      self.save
    end
  end
end