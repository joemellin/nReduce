class Response < ActiveRecord::Base
  belongs_to :request
  belongs_to :user
  has_many :notifications, :as => :attachable
  has_one :account_transaction, :as => :attachable

  serialize :data, Array

  validates_presence_of :request_id
  validates_presence_of :user_id
  validate :request_is_open, :if => :new_record?
  validate :user_hasnt_already_performed_request_or_created_request, :if => :new_record?
  validate :questions_are_answered, :if => :completed?
  
  after_initialize :set_default_status
  after_create :decrement_request_num

  before_destroy :increment_request_on_destroy

  attr_accessible :data, :amount_paid, :rejected_because, :request, :request_id, :user, :user_id

  bitmask :status, :as => [:started, :completed, :accepted, :rejected, :expired, :canceled]

  # Finds all responses started more than an hour ago and expires them
  def self.expire_all_uncompleted_responses
    Response.transaction do
      Response.where(['created_at < ?', Time.now - 1.day]).with_status(:started).each{|r| r.expire! if r.should_be_expired? }
    end
  end

  def title
    return self.extra_data['tweet_content'] if self.request_type == [:retweet] && self.extra_data['tweet_content'].present?
    self['title']
  end

  def data=(new_data)
    # Allows us to post from form with specific order of hash
    if new_data.is_a?(Hash)
      self['data'] = new_data.sort.map{|arr| arr.last}
    else
      self['data'] = new_data
    end
    self['data']
  end

    # Completes the task and verifies it has been completed
  def complete!
    return true if self.completed?
    self.status = :completed
    self.completed_at = Time.now
    # retweet / upvote / etc
    self.perform_request_specific_tasks
    self.save
  end

    # Returns boolean if this response is valid and can be completed
  def can_be_completed?
    self.valid? && self.questions_are_answered && self.started?
  end

  def expires_at
    mins = Settings.requests.expire_in_minutes.send(self.request_type)
    self.created_at + mins.to_i.minutes
  end

  def should_be_expired?
    (self.expires_at < Time.now) && self.started?
  end

    # Once a requesting user has reviewed it they can accept it
    # Can pass in amount paid if different than what was offered on the request
  def accept!(amount_paid = nil)
    return true if self.accepted? || self.rejected?
    self.amount_paid = amount_paid || self.request.user_can_earn(self.user)
    self.questions_are_answered
    self.validate_balance_is_available
    return false unless self.valid?
    self.status = :accepted
    self.accepted_at = Time.now
    Response.transaction do
      if self.save && self.decrement_request_num(self.amount_paid) && self.pay_user
        true
      else
        false
      end
    end
  end

  # Once a requesting user has reviewed it they can reject it (reason needed)
  def reject!(reason)
    return true if self.accepted? || self.rejected?
    self.rejected_because = reason
    self.cancel!(:rejected)
  end

  # Request has gone past expiry - only allow to expire if it hasn't been completed
  def expire!
    return false unless self.started?
    self.expired_at = Time.now
    self.cancel!(:expired)
  end

  # Save and increment the number of responses on the request
  def cancel!(status = :canceled)
    Response.transaction do
      self.status = status
      if self.save && self.increment_request_num
        true
      else
        false
      end
    end
  end

  def questions
    self.request.data
  end

  def request_type
    self.request.request_type.first
  end

  def started?
    self.status == [:started]
  end

  def accepted?
    self.status == [:accepted]
  end

  def completed?
    self.status == [:completed]
  end

  def rejected?
    self.status == [:rejected]
  end

  def expired?
    self.status == [:expired]
  end

  def canceled?
    self.status == [:canceled]
  end

  def perform_request_specific_tasks
    if self.request_type == :retweet && Rails.env.production? && !self.completed?
      tc = self.user.twitter_client
      if tc.present? && self.request.extra_data['tweet_id'].present?
        rt = tc.retweet(self.request.extra_data['tweet_id'])
        if rt.present?
          self.extra_data['retweet_id'] = rt
          self.extra_data['followers_count'] = self.user.followers_count
        else
          self.errors.add(:data, "Could not retweet the original tweet. Please try again later")
        end
      else
        self.errors.add(:user, "doesn't have a valid Twitter authentication - please add it again") if tc.blank?        
      end
    end
  end

  protected

  def set_default_status
    self.status = :started if self.status.blank?
  end

  # Increment num of requests avail - if a response is canceled
  def increment_request_num(num = 1)
    self.request.num += num
    self.request.save
  end

  def decrement_request_num(num = 1)
    self.request.num -= num
    self.request.num = 0 if self.request.num < 0
    self.request.save
  end

  def request_is_open
    if self.request.num == 0
      self.errors.add(:request, "the helpful request has already been fulfilled - please choose another one")
      false
    else
      true
    end
  end

  # Validates startup can pay for this response, and that num on request is above 0
  def validate_balance_is_available
    if AccountTransaction.sufficient_funds?(self.request.startup, self.amount_paid, :escrow)
      self.errors.add(:request, "startup doesn't have enough helpfuls to pay you, sorry")
      false
    else
      true
    end
  end

  def pay_user
    !AccountTransaction.transfer(self.amount_paid, self.request.startup.account, self.user.account, :escrow, :balance).new_record?
  end

  def user_hasnt_already_performed_request_or_created_request
    res = true
    if self.request.startup_id == self.user.startup_id || self.request.user_id == self.user_id
      self.errors.add(:user, "User made help request - therefore can't respond")
      res = false
    end
    if Response.where(:request_id => self.request_id, :user_id => self.user_id).with_status(:completed, :rejected).count > 0
      self.errors.add(:user, "has already responded to this help request")
      res = false
    end
    res
  end

  def questions_are_answered
    # These types of responses don't need any input from the user
    return true if [:retweet, :hn_upvote].include?(self.request_type)
    # Otherwise check to see if user has answered all questions
    if self.data.present? && self.data.select{|q| q.present? }.size == self.questions.size
      true
    else
      self.errors.add(:data, "questions haven't all been answered")
      false
    end
  end

  def increment_request_on_destroy
    self.increment_request_num if !self.new_record? && (self.started? || self.completed? || self.accepted?)
    true
  end
end