class Request < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user
  has_many :responses
  has_many :notifications, :as => :attachable
  has_many :account_transactions, :as => :attachable

  before_create :transfer_balance_to_escrow

  validates_presence_of :request_type
  validates_numericality_of :num, :greater_than_or_equal_to => 0
  validate :price_is_correct  
  validates_presence_of :startup_id
  validates_presence_of :user_id
  validates_presence_of :price
  validate :questions_are_answered
  validate :balance_is_available_for_request, :if => :new_record?

  serialize :data, Array

  attr_accessible :title, :request_type, :price, :num, :data, :startup, :startup_id, :user, :user_id

  bitmask :request_type, :as => [:retweet, :hn_upvote, :ui_ux_feedback, :value_prop_feedback]

  scope :available, where('num != 0')
  scope :closed, where(:num => 0)

  def questions
    Settings.request_questions.send(self.request_type.first.to_s)
  end

  def total_price
    self.num * self.price
  end

  def closed?
    self.num == 0
  end

  def close!
    num_started = self.responses.with_status(:started).count
    # only allow it to be closed at number of started (unfinished) requests
    if num_started > 0
      #self.errors.add(:num, "responses are open - we have closed the request for any new responses but you have to wait for those to complete")
      self.num = num_started
    else
      self.num = 0
    end
    self.save  
  end

  protected

  def price_is_correct
    if self.request_type.present?
      self.price = Settings.request_prices.send(self.request_type.first.to_s) if self.price.blank? || self.new_record? || self.request_type_changed?
    end
    true
  end

  def transfer_balance_to_escrow
    !AccountTransaction.transfer(self.total_price, self.startup.account, self.startup.account, :balance, :escrow).new_record?
  end

  def balance_is_available_for_request
    self.errors.add(:num, "of responses required must be more than 0") if self.num == 0
    if self.startup.present? && !AccountTransaction.sufficient_funds?(self.startup, self.total_price)
      self.errors.add(:startup, "doesn't have enough of a balance to make this request (#{self.total_price} helpfuls required)")
      false
    else
      true
    end
  end

  def questions_are_answered
    if self.data.present? && self.data.select{|q| q.present? }.size == self.questions.size
      true
    else
      self.errors.add(:data, "questions haven't all been written")
      false
    end
  end
end