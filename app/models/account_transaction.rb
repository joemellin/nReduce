class AccountTransaction < ActiveRecord::Base
  # ALL AMOUNTS ARE IN HELPFULS
  belongs_to :attachable, :polymorphic => true
  belongs_to :from_account, :class_name => 'Account'
  belongs_to :to_account, :class_name => 'Account'
  has_one :payment

  # attr_accessible :title, :body
  validates_presence_of :from_account_id, :if => :transfer?
  validates_presence_of :from_account_type, :if => :transfer?
  validates_presence_of :to_account_id
  validates_presence_of :to_account_type
  validates_presence_of :amount
  validate :account_types_are_valid

  bitmask :transaction_type, :as => [:transfer, :deposit]

  # Wraps the whole transfer in a transaction to ensure it is completed
  def self.transfer(amount, from_account, to_account, from_account_type = :balance, to_account_type = :balance)
    t = AccountTransaction.new
    t.amount, t.from_account, t.to_account, t.from_account_type, t.to_account_type = amount, from_account, to_account, from_account_type, to_account_type
    t.transaction_type = :transfer
    AccountTransaction.transaction do
      if t.valid? && t.from_account_has_balance?
        t.from_account.send("#{t.from_account_type}=", t.from_balance - t.amount)
        t.to_account.send("#{t.to_account_type}=", t.to_balance + t.amount)
        t.from_account.save
        t.to_account.save
        t.save
      end
    end
    t
  end

  # Deposit (from cash payment) into an account
  def self.deposit(amount, to_account)
    t = AccountTransaction.new
    t.amount, t.to_account = amount, to_account
    t.transaction_type = :deposit
    t.to_account_type = :balance
    AccountTransaction.transaction do
      if t.valid?
        t.to_account.send("#{t.to_account_type}=", t.to_balance + amount)
        t.to_account.save
        t.save
      end
    end
    t
  end

  # Returns boolean whether funds are available
  # Can pass in an actual account or a model that has been made 'accountable' with the module
  def self.sufficient_funds?(account, amount, account_type = :balance)
    account.send(account_type) >= amount
  end

  def self.valid_account_types
    [:balance, :escrow]
  end

  def from_balance
    self.from_account.send(self.from_account_type)
  end

  def to_balance
    self.to_account.send(self.to_account_type)
  end

  def from_account_has_balance?
    AccountTransaction.sufficient_funds?(self.from_account, self.amount, self.from_account_type)
  end

  def transfer?
    self.transaction_type == [:transfer]
  end

  def deposit?
    self.transaction_type == [:deposit]
  end

  protected

  def account_types_are_valid
    val = true
    if self.from_account_type.present? && !AccountTransaction.valid_account_types.include?(self.from_account_type.to_sym) 
      self.errors.add(:from_account_type, "isn't a valid account type") 
      val = false
    end
    if self.to_account_type.present? && !AccountTransaction.valid_account_types.include?(self.to_account_type.to_sym)
      self.errors.add(:to_account_type, "isn't a valid account type")
      val = false
    end
    val
  end
end
