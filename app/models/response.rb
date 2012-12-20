class Response < ActiveRecord::Base
  belongs_to :request
  belongs_to :user
  belongs_to :video
  has_many :notifications, :as => :attachable
  has_one :account_transaction, :as => :attachable

  serialize :data #, Hash

  validates_presence_of :request_id
  validates_presence_of :user_id
  validates_presence_of :amount_paid
  validates_presence_of :video_id, :if => :video_required?
  validate :request_is_open, :if => :new_record?
  validate :user_hasnt_already_performed_request_or_created_request, :if => :new_record?
  validate :questions_are_answered, :if => :completed?
  
  after_initialize :set_default_status_and_data, :if => :new_record?
  after_create :decrement_request_by_amount_paid

  before_destroy :increment_request_on_destroy

  attr_accessible :data, :amount_paid, :rejected_because, :request, :request_id, :user, :user_id, :video_attributes

  accepts_nested_attributes_for :video, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true

  bitmask :status, :as => [:started, :completed, :accepted, :rejected, :expired, :canceled]

  attr_accessor :ready_to_accept

  # Finds all responses started more than an hour ago and expires them
  def self.expire_all_uncompleted_responses
    Response.transaction do
      Response.where(['created_at < ?', Time.now - 1.day]).with_status(:started).each{|r| r.expire! if r.should_be_expired? }
    end
  end

  def title
    return self.extra_data['tweet_content'] if self.request_type == 'RetweetRequest' && self.extra_data['tweet_content'].present?
    self['title']
  end

    # Completes the task and verifies it has been completed
  def complete!
    return true if self.completed?
    
    # Retweet / upvote / etc - must be performed before assigning completion flag
    self.perform_request_specific_tasks

    # Auto-accept if task doesn't need confirmation from requestor
    self.status = :completed
    self.completed_at = Time.now
    
    if self.ready_to_accept == true
      res = self.accept!
    else
      res = self.save
    end
    Notification.create_for_response_completed(self) if res == true
    res
  end

    # Returns boolean if this response is valid and can be completed
  def can_be_completed?
    self.valid? && self.questions_are_answered && self.started?
  end

  def expires_at
    (self.created_at || Time.now) + self.request.response_expires_in
  end

  def expires_at_minutes
    ((self.expires_at - Time.now) / 60).round
  end

  def should_be_expired?
    (self.expires_at < Time.now) && self.started?
  end

  def video_required?
    self.accepted? && self.request.present? && self.request.video_required?
  end

    # Once a requesting user has reviewed it they can accept it
    # Can pass in amount paid if different than what was offered on the request
  def accept!
    return true if self.accepted? || self.rejected?
    self.questions_are_answered
    self.validate_balance_is_available
    return false unless self.valid?
    self.status = :accepted
    self.accepted_at = Time.now
    Response.transaction do
      if self.save && self.pay_user
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
      if self.save && self.increment_request_by_amount_paid
        true
      else
        false
      end
    end
  end

  def thanked!
    self.thanked = true
    self.save
  end

  def questions
    self.request.response_questions
  end

  def request_type
    self.request.blank? ? nil : self.request.type
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
    if self.request_type == 'RetweetRequest' && !self.completed?
      if Rails.env.production?
        tc = self.user.twitter_client
        if tc.present? && self.request.extra_data['tweet_id'].present?
          rt = tc.retweet(self.request.extra_data['tweet_id'])
          if rt.present?
            self.extra_data ||= {}
            self.extra_data['retweet_id'] = rt
            self.extra_data['followers_count'] = self.user.followers_count
            self.ready_to_accept = true
          else
            self.errors.add(:data, "Could not retweet the original tweet. Please try again later")
          end
        else
          self.errors.add(:user, "doesn't have a valid Twitter authentication - please add it again") if tc.blank?        
        end
      else # auto-accept in dev/test
        self.ready_to_accept = true
      end
    end
  end

  def amount_paid
    return self['amount_paid'] unless self['amount_paid'] == 0
    self['amount_paid'] = self.request.user_can_earn(self.user) if self.request_id.present? && self.user_id.present?
    self['amount_paid']
  end

  def questions_are_answered
    # These types of responses don't need any input from the user
    return true if ['RetweetRequest'].include?(self.request_type)
    # Otherwise check to see if user has answered all questions
    if self.data.present? && self.data.keys == self.questions.keys
      true
    else
      self.errors.add(:data, "questions haven't all been answered")
      false
    end
  end

  protected

  def set_default_status_and_data
    self.data ||= {}
    self.status = :started if self.status.blank?
  end

  # Increment num of requests avail - if a response is canceled
  def increment_request_by_amount_paid
    self.request.adjust_num_from_amount_paid(self.amount_paid)
  end

  def decrement_request_by_amount_paid
    self.request.adjust_num_from_amount_paid(0 - self.amount_paid)
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
    if AccountTransaction.sufficient_funds?(self.request.startup.account, self.amount_paid, :escrow)
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

  def increment_request_on_destroy
    # don't increment if already paid
    self.increment_request_by_amount_paid if !self.new_record? && !self.accepted? && (self.started? || self.completed?)
    true
  end
end