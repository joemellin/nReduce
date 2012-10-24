class Question < ActiveRecord::Base
  # @@pusher_socket = nil
  # @@pusher_channel = nil

  belongs_to :user
  belongs_to :startup

  serialize :supporter_ids, Array

  attr_accessible :content, :startup, :startup_id, :tweet, :user

  validates :user_id, :startup_id, :presence => true
  validates :content, :length => { :maximum => 90, :minimum => 10 }

  before_create :update_followers_and_attendees
  before_create :tweet_question
  after_save :update_cache

  scope :unanswered, where('answered_at IS NULL')
  scope :ordered, order('followers_count DESC')

  attr_accessor :unseen

  def self.last_changed_at_for_startup(startup)
    last_changed = Cache.get(['questions_changed_at', startup], nil, true){
      q = startup.questions.unanswered.ordered.first
      q.present? ? q.updated_at.to_s : Time.now.to_s
    }
    Time.parse(last_changed)
  end

  def self.unanswered_for_startup(startup)
    question_ids = Cache.get(['question_ids', startup]){
      startup.questions.unanswered.ordered.map{|q| q.id }
    }
    Question.where(:id => question_ids)
  end

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
    # Retweet from supporter's account - commented out as we're not doing it for now
    # if !dont_tweet && self.tweet_id.present?
    #   tw = user.twitter_client
    #   self.followers_count += user.followers_count if user.followers_count.present?
    #   tw.retweet(self.tweet_id) if Rails.env.production?
    # end
    self.followers_count += user.followers_count if user.followers_count.present?
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
    begin
      "#{self.content.first(90)} #{Settings.demo_day.hashtag} http://nreduce.com/d/#{DemoDay.next_or_current.index_of(self.startup)}"
    rescue
      ''
    end
  end

  # Tweets question from creator's account
  def tweet_question
    return true #unless Rails.env.production? && self.tweet?
    tw = self.user.twitter_client
    return false if tw.blank?
    begin
      tweet = tw.update(self.tweet_content)
    rescue Twitter::Error::Forbidden
      self.errors.add(:startup_id, 'has already been asked this same question by you -- please rephrase it')
      return false
    end
    # Save tweet id
    self.tweet_id = tweet.id if tweet.present?
    true
  end

  # def self.pusher_socket
  #   if @@pusher_socket.blank?
  #     @@pusher_socket = PusherClient::Socket.new(Settings.apis.pusher.key, {:secret => Settings.apis.pusher.secret})
  #   end
  #   @@pusher_socket
  # end

  # def self.pusher_channel
  #   if @@pusher_channel.blank?
  #     @@pusher_channel = Question.pusher_socket.subscribe('test_channel')
  #   end
  #   @@pusher_channel
  # end

  protected

  def update_cache
    Cache.set(['questions_changed_at', self.startup], Time.now.to_s, nil, true)
    Cache.delete(['question_ids', startup])
  end

  def add_attendee_to_demo_day(attendee)
    dd = DemoDay.next_or_current
    dd.add_attendee!(attendee, true) if dd.present?
  end

  def update_followers_and_attendees
    # Don't update if we are nReduce answering questions for weekly join
    return if self.startup_id == Startup.nreduce_id
    self.followers_count = self.user.followers_count if self.user.followers_count.present?
    self.add_attendee_to_demo_day(self.user)
  end
end