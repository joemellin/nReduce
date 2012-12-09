class AccountTransfer < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  belongs_to :from_account, :class_name => 'Account'
  belongs_to :to_account, :class_name => 'Account'

  # attr_accessible :title, :body
  validates_presence_of :from_account_id
  validates_presence_of :to_account_id
  validates_presence_of :from_account_type
  validates_presence_of :to_account_type
  validates_presence_of :amount
  validate :account_types_are_valid

  # Wraps the whole transfer in a transaction to ensure it is completed
  def self.perform(from_account, to_account, from_account_type, to_account_type, amount)
    t = AccountTransfer.new
    t.from_account, t.to_account, t.from_account_type, t.to_account_type, t.amount = from_account, to_account, from_account_type, to_account_type, amount
    Account.transaction do
      if t.valid? && t.from_account_has_balance?
        from_account.send("#{from_account_type}=", t.from_balance - amount)
        to_account.send("#{to_account_type}=", t.to_balance + amount)
        from_account.save
        to_account.save
        return true if t.save
      end
    end
    false
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
    self.from_account.send(self.from_account_type) >= self.amount
  end

  protected

  def account_types_are_valid
    self.errors.add(:from_account_type, "isn't a valid account type") unless AccountTransfer.valid_account_types.include?(self.from_account_type.to_sym)
    self.errors.add(:to_account_type, "isn't a valid account type") unless AccountTransfer.valid_account_types.include?(self.to_account_type.to_sym)
  end
  
end
