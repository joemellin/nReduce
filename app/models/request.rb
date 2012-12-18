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
    AccountTransaction.sufficient_funds?(self.startup.account, self.total_price)
  end

  def user_can_earn(user)
    # completely variable pricing based on followers count
    if self.request_type_s == 'retweet'
      num_followers = user.followers_count.present? ? user.followers_count : 0
      # price is per 100 followers
      avail = (user.followers_count.to_f / 100.0).floor
      avail = num if avail > num
      self.price * avail
    else
      self.price
    end
  end

  def adjust_num_from_amount_paid(amount_paid)
    return true if amount_paid == 0
    self.num += amount_paid / self.price
    self.save
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

  # Cancel/delete a request - only if no responses
  def cancel!
    if AccountTransaction.transfer(self.num * self.price, self.startup.account, self.startup.account, :escrow, :balance).new_record?
      self.errors.add(:num, 'could not be refunded to your startup\'s balance') 
      return false
    end
    if self.responses.count > 0
      self.num = 0
      self.save
    else
      self.destroy
    end
  end

  def request_type_human
    self.request_type_s.titleize
  end

  protected

  def perform_request_specific_setup_tasks
    if self.request_type.first == :retweet
      # Get tweet id and tweet content
      if Rails.env.production?
        self.extra_data ||= {}
        unless self.data.blank?
          match = self.data.first.strip.match(/[0-9]+$/)
          self.extra_data['tweet_id'] = match[0] if match.present?
        end
        self.extra_data['tweet_content'] = Twitter.status(self.extra_data['tweet_id']).text unless self.extra_data['tweet_id'].blank?
        if self.extra_data['tweet_content'].blank?
          self.errors.add(:data, 'says: "You need to put in a valid Twitter URL"') 
          return false
        end
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
    if self.startup.present? && !self.startup_has_balance?
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