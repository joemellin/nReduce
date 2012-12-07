class Request < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user
  has_many :responses
  has_many :notifications, :as => :attachable

  before_validation :set_default_price
  validates_numericality_of :num, :greater_than_or_equal_to => 1
  validates_presence_of :startup_id
  validates_presence_of :user_id
  validates_presence_of :price
  validate :questions_are_answered
  validate :balance_is_available_for_request

  serialize :data, Array

  attr_accessible :title, :request_type, :price, :num, :data, :startup, :startup_id, :user, :user_id

  bitmask :request_type, :as => [:retweet, :hn_upvote, :ui_ux_feedback, :value_prop_feedback]

  scope :open, where('num != 0')
  scope :closed, where(:num => 0)

  def questions
    Settings.request_questions.send(self.request_type.first.to_s)
  end

  # Call when a user is starting a request - as we need to lock this from being responded to too many people at once
  def start_response(user)
    # Don't do anything if people have already answered
    return false if self.closed?
    Response.create(:request => self, :user => user)
  end

  def helpfuls_required
    self.set_default_price
    self.num * self.price
  end

  # Set default price if blank or less than default
  def set_default_price
    default_price = Settings.request_prices.send(self.request_type.first.to_s)
    self.price = default_price if self.price.blank? || (self.price.present? && self.price < default_price)
    true
  end

  def closed?
    self.num == 0
  end

  protected

  def balance_is_available_for_request
    if self.startup.helpful_balance < self.price
      self.errors.add(:startup, "doesn't have enough of a balance to make this request (#{self.helpfuls_required} helpfuls required)")
      false
    end
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