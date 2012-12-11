class Request < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user
  has_many :responses
  has_many :notifications, :as => :attachable
  has_many :account_transactions, :as => :attachable

  after_initialize :set_price, :if => :new_record?
  before_create :transfer_balance_to_escrow
  before_create :perform_request_specific_setup_tasks

  validates_presence_of :request_type
  validates_numericality_of :num, :greater_than_or_equal_to => 0
  validate :set_price
  validates_presence_of :startup_id
  validates_presence_of :user_id
  validates_presence_of :price
  validates_presence_of :title, :if => :title_required?
  validate :questions_are_answered
  validate :balance_is_available_for_request, :if => :new_record?

  serialize :data, Array
  serialize :extra_data, Hash

  attr_accessible :title, :request_type, :price, :num, :data, :startup, :startup_id, :user, :user_id

  bitmask :request_type, :as => [:retweet, :hn_upvote, :ui_ux_feedback, :value_prop_feedback]

  scope :available, where('num != 0')
  scope :closed, where(:num => 0)
  scope :ordered, order('created_at DESC')

  def startup_has_balance?
    self.startup.balance >= self.total_price
  end

  def title_required?
    self.request_type_s != 'retweet'
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

  def request_type_s
    self.request_type.first.to_s
  end

  def questions
    Settings.requests.questions.send(self.request_type_s)
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

  def request_type_human
    self.request_type_s.titleize
  end

  protected

  def perform_request_specific_setup_tasks
    if self.request_type.first == :retweet
      # Get tweet id and tweet content
      self.extra_data['tweet_id'] = self.data.first.strip.match(/[0-9]+$/)[0] unless self.data.blank?
      self.extra_data['tweet_content'] = Twitter.status(self.extra_data['tweet_id']).text unless self.extra_data['tweet_id'].blank?
      if self.extra_data['tweet_content'].blank?
        self.errors.add(:data, 'did not contain a valid Twitter status URL') 
        return false
      end
    end
    true
  end

  def set_price
    if self.request_type.present?
      self.price = Settings.requests.prices.send(self.request_type_s) if self.price.blank? || self.new_record? || self.request_type_changed?
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
    if self.questions.present?
      if self.data.present? && self.data.select{|q| q.present? }.size == self.questions.size
        true
      else
        self.errors.add(:data, "questions haven't all been written")
        false
      end
    else
      true
    end
  end
end