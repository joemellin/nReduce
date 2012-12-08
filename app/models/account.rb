class Account < ActiveRecord::Base
  belongs_to :owner, :polymorphic => true
  has_many :outgoing_transfers, :class_name => 'AccountTransfer', :foreign_key => :from_account_id
  has_many :incoming_transfers, :class_name => 'AccountTransfer', :foreign_key => :to_account_id

  validates_numericality_of :balance, :greater_than_or_equal_to => 0
  validates_numericality_of :escrow, :greater_than_or_equal_to => 0
end
