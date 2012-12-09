class Response < ActiveRecord::Base
  belongs_to :request
  belongs_to :user
  has_many :notifications, :as => :attachable
  has_one :account_transfer, :as => :attachable

  serialize :data, Array

  validates_presence_of :request_id
  validates_presence_of :user_id
  validate :request_is_open, :if => :new_record?
  validate :user_hasnt_already_performed_request, :if => :new_record?
  
  before_create :set_default_status
  after_create :decrement_request_num

  attr_accessible :data, :amount_paid, :rejected_because, :request, :request_id, :user, :user_id

  bitmask :status, :as => [:started, :completed, :accepted, :rejected, :expired, :canceled]

  def complete!(data)
    self.data = data
    self.status = :completed
    self.completed_at = Time.now
    self.save
  end

    # Once a requesting user has reviewed it they can accept it
    # Can pass in amount paid if different than what was offered on the request
  def accept!(amount_paid = nil)
    return true if self.accepted? || self.rejected?
    self.amount_paid = amount_paid || self.request.price
    self.validate_questions_are_answered
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

  protected

  def set_default_status
    self.status = :started
  end

  # Increment num of requests avail - if a response is canceled
  def increment_request_num
    self.request.num += 1
    self.request.save
  end

  def decrement_request_num
    self.request.num -= 1
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
    if self.request.startup.escrow < self.amount_paid
      self.errors.add(:request, "startup doesn't have enough helpfuls to pay you, sorry")
      false
    else
      true
    end
  end

  def pay_user
    AccountTransfer.perform(self.request.startup.account, self.user.account, :escrow, :balance, self.amount_paid)
  end

  def user_hasnt_already_performed_request
    if Response.where(:request_id => self.request_id, :user_id => self.user_id).count > 0
      self.errors.add(:user, "has already responded to this help request")
      false
    else
      true
    end
  end

  def validate_questions_are_answered
    if self.data.present? && self.data.select{|q| q.present? }.size == self.questions.size
      true
    else
      self.errors.add(:data, "questions haven't all been answered")
      false
    end
  end
end