class Request < ActiveRecord::Base
  belongs_to :startup
  belongs_to :user
  has_many :responses
  has_many :notifications, :as => :attachable
  has_many :account_transactions, :as => :attachable

  after_initialize :set_price, :if => :new_record?
  after_initialize :ensure_defaults_exist
  before_create :transfer_balance_to_escrow
  before_create :perform_request_specific_setup_tasks

  before_validation :set_price, :if => :new_record?
  validates_presence_of :type
  validates_numericality_of :num, :greater_than_or_equal_to => 0
  validates_presence_of :startup_id
  validates_presence_of :user_id
  validates_presence_of :price
  validates_presence_of :title, :if => :title_required?
  validate :questions_are_answered
  validate :balance_is_available_for_request, :if => :new_record?

  serialize :data #, Hash
  serialize :extra_data, Hash

  attr_accessible :title, :type, :num, :data, :startup, :startup_id, :user, :user_id

  #bitmask :request_type, :as => [:retweet, :hn_upvote, :ui_ux_feedback, :value_prop_feedback]

  scope :available, where('num != 0')
  scope :closed, where(:num => 0)
  scope :ordered, order('created_at DESC')

  #
  # START OF METHODS that each child class should override
  #

  def self.defaults
    {
     :price => 1,
     :pricing_unit => '',
     :pricing_step => 0,
     :response_expires_in => 30.minutes,
     :title_required => true,
     :video_required => false,
     :questions => {},
     # questions are a hash with an array per key, ex: {'age' => ['What is your age?', 'field type (string, text, integer)', 'optional placeholder text']}
     # keys must be strings for easier comparison with saved objects
     :response_questions => {}
    }
  end

  def user_can_earn(user)
    self.price
  end

  def perform_request_specific_setup_tasks
    true
  end

  # Uncomment this in each child class so we can use STI and have routes work properly
  # def self.model_name
  #   Request.model_name
  # end

  #
  # END METHODS TO OVERRIDE
  #

  def self.defaults_keys
    [:price, :pricing_unit, :pricing_step, :response_expires_in, :title_required, :questions, :response_questions, :video_required]
  end

  def default_price
    self.class.defaults[:price]
  end

  def type_human
    self.class.to_s.gsub('Request', '').titleize
  end

  def pricing_unit
    self.class.defaults[:pricing_unit]
  end

  def pricing_step
    self.class.defaults[:pricing_step]
  end

  def questions
    self.class.defaults[:questions]
  end

  def response_expires_in
    self.class.defaults[:response_expires_in]
  end

  def title_required?
    self.class.defaults[:title_required]
  end

  def video_required?
    self.class.defaults[:video_required]
  end

  def response_questions
    self.class.defaults[:response_questions]
  end

  # Does the startup requesting this have enough of a balance yo pay for it?
  def startup_has_balance?
    AccountTransaction.sufficient_funds?(self.startup.account, self.total_price)
  end

  # Adjust the request to have the right num left, depending on how much was paid
  def adjust_num_from_amount_paid(amount_paid)
    return true if amount_paid == 0
    self.num += amount_paid / self.price
    self.save
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

  protected

  def ensure_defaults_exist
    self.data ||= {}
    if self.class.defaults.keys != Request.defaults_keys
      self.errors.add(:type, "doesn't have all required defaults")
      false
    else
      true
    end
  end

  def set_price
    self.price = self.default_price
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
      if self.data.present? && self.data.is_a?(Hash) && self.data.keys == self.questions.keys
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