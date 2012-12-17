module Accountable
  # include this module on any model you'd like to be able to have an account
  def self.included(base)
    # Adding relationships here so it doesn't complain that active_record isn't avail
    base.class_eval do
      has_one :account, :as => :owner
    end
  end

  def account_transactions
    self.account.account_transactions
  end

  def cached_account
    Account.cached_account_for_owner(self)
  end

  def balance
    self.cached_account.first
  end

  def escrow
    self.cached_account.last
  end
end