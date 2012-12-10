require 'spec_helper'

describe Payment do
  before :each do 
    @startup = FactoryGirl.create(:startup)
    @account = Account.create_for_owner(@startup)

    @payment = Payment.new
    @payment.amount = 10.00
    @payment.num_helpfuls = 10
    @payment.account = @account
    @payment.stripe_id = '234k3js033'
  end
  
  describe "when buying helpfuls" do
    it "should allow us to make a payment and receive a deposit to our account" do
      prev_balance = @account.balance
      @payment.status = :completed
      @payment.save.should be_true

      @account.reload
      @account.balance.should == prev_balance + 10

      # make sure it doesn't deposit twice on save
      @payment.save
      @account.reload
      @account.balance.should == prev_balance + 10
    end

    it "shouldn't deposit a payment if it isn't successful" do
      prev_balance = @account.balance
      @payment.status = :failed
      @payment.save.should be_true

      @account.reload
      @account.balance.should == prev_balance
    end
  end
end
