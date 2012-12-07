class Response < ActiveRecord::Base
  belongs_to :request
  belongs_to :user
  has_many :notifications, :as => :attachable

  serialize :data, Array

  validates_presence_of :request_id
  validates_presence_of :user_id
  validate :request_is_open, :if => :new_record?
  validate :user_hasnt_already_performed_request, :if => :new_record?
  
  after_create :decrement_request_num

  attr_accessible :data, :amount_paid, :rejected_because, :request, :request_id, :user, :user_id

  scope :rejected, where('rejected_because IS NOT NULL')
  scope :accepted, where('accepted_at IS NOT NULL')
  scope :started, where('accepted_at IS NULL')

    # Once a requesting user has reviewed it they can accept it
    # Can pass in amount paid if different than what was offered on the request
  def accept!(amount_paid = nil)
    self.validate_questions_are_answered
    self.validate_balance_is_available
    if self.valid?
      self.accepted_at = Time.now
      self.amount_paid = amount_paid || self.request.price
      self.save
    else
      false
    end
  end

  # Once a requesting user has reviewed it they can reject it (reason needed)
  def reject(reason)
    self.rejected_because = reason
    self.accepted_at = nil
    if self.save
      self.increment_request_num
    else
      false
    end
  end

  def questions
    self.request.data
  end

  protected

  # Increment num of requests avail - if a response is canceled
  def increment_request_num
    self.request.update_attribute('num', self.request.num + 1)
  end

  def decrement_request_num
    self.request.update_attribute('num', self.request.num - 1)
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
    if self.startup.helpful_balance < self.price
      self.errors.add(:request, "startup doesn't have enough helpfuls to pay you, sorry")
      false
    else
      true
    end
  end

  def 

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