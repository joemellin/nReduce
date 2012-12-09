class Account < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  has_many :outgoing_transfers, :class_name => 'AccountTransfer', :foreign_key => :from_account_id
  has_many :incoming_transfers, :class_name => 'AccountTransfer', :foreign_key => :to_account_id

  validates_numericality_of :balance, :greater_than_or_equal_to => 0
  validates_numericality_of :escrow, :greater_than_or_equal_to => 0

  after_save :set_cached_object

  def self.cached_account_for_owner(owner, dont_create = false)
    Cache.get([owner, 'account']){
      account = owner.account
      return nil if account.blank? && !dont_create
      account ||= Account.create_for_owner(owner)
      account.to_array
    }
  end

  def self.create_for_owner(owner)
    account = Account.new
    account.owner = owner
    account.save
    account
  end

  def to_array
    [self.balance, self.escrow]
  end

  protected

  def set_cached_object
    Cache.set([self.owner, 'account'], self.to_array)
  end
end
