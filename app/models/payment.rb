class Payment < ActiveRecord::Base
  # AMOUNT is dollars, NUM_HELPFULS is equivalent helpfuls
  belongs_to :account
  belongs_to :user
  belongs_to :account_transaction

  validates_presence_of :account_id
  validates_presence_of :stripe_id
  validates_presence_of :status

  # Has to be after payment is completed - because we can always complete transfer, but don't want to have to redo payment
  after_create :deposit_payment

  bitmask :status, :as => [:started, :completed, :canceled, :failed]

  def completed?
    self.status == [:completed]
  end

  def cancel!
    self.status = :canceled
    self.save
  end

  protected

  def deposit_payment
    # Make sure it only transfers once on a successful transaction
    if self.completed? && self.account_transaction.blank?
      self.account_transaction = AccountTransaction.deposit(self.num_helpfuls, self.account)
      if self.account_transaction.new_record?
        errors.add(:account_transaction, "could not be completed to fill account with helpfuls")
        return false
      end
    end
    true
  end
end