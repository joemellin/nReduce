require 'spec_helper'

describe AccountTransfer do
  before :each do 
    @startup1 = FactoryGirl.create(:startup)
    @startup2 = FactoryGirl.create(:startup, :name => 'Facebook for Dinosaurs')
    @account1 = Account.create_for_owner(@startup1)
    @account2 = Account.create_for_owner(@startup2)
  end

  describe "Transfer between accounts" do
    it "shouldn't allow transfer between blank accounts" do
      AccountTransfer.perform(@account1, @account2, :balance, :balance, 5).should be_false
      AccountTransfer.perform(@account1, @account2, :balance, :escrow, 5).should be_false
      AccountTransfer.perform(@account1, @account1, :balance, :balance, 5).should be_false
    end

    it "should allow to transfer between accounts" do
      @account1.balance = 6
      @account1.save
      @startup1.balance.should == 6
      AccountTransfer.perform(@account1, @account2, :balance, :balance, 5).should be_true

      @account2.reload
      @account2.balance.should == 5
      @startup2.balance.should == 5
      @account1.reload
      @account1.balance.should == 1
      @startup1.balance.should == 1
    end

    it "should be allowed to transfer between internal accounts on one account" do
      @account1.balance = 6
      @account1.save
      AccountTransfer.perform(@account1, @account1, :balance, :escrow, 5).should be_true

      @account1.reload
      @account1.balance.should == 1
      @startup1.balance.should == 1
      @account1.escrow.should == 5

      AccountTransfer.perform(@account1, @account2, :escrow, :balance, 5).should be_true
      @startup2.balance.should == 5
    end
  end
end
