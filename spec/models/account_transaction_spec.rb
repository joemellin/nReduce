require 'spec_helper'

describe AccountTransaction do
  before :each do 
    @startup1 = FactoryGirl.create(:startup)
    @startup2 = FactoryGirl.create(:startup, :name => 'Facebook for Dinosaurs')
    @account1 = Account.create_for_owner(@startup1)
    @account2 = Account.create_for_owner(@startup2)
  end

  describe "Transfer between accounts" do
    it "shouldn't allow transfer between blank accounts" do
      AccountTransaction.transfer(5, @account1, @account2, :balance, :balance).new_record?.should be_true
      AccountTransaction.transfer(5, @account1, @account2, :balance, :escrow).new_record?.should be_true
      AccountTransaction.transfer(5, @account1, @account1, :balance, :balance).new_record?.should be_true
    end

    it "should allow to transfer between accounts" do
      @account1.balance = 6
      @account1.save
      @startup1.balance.should == 6
      AccountTransaction.transfer(5, @account1, @account2, :balance, :balance).new_record?.should be_false

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
      AccountTransaction.transfer(5, @account1, @account1, :balance, :escrow).new_record?.should be_false

      @account1.reload
      @account1.balance.should == 1
      @startup1.balance.should == 1
      @account1.escrow.should == 5

      AccountTransaction.transfer(5, @account1, @account2, :escrow, :balance).new_record?.should be_false
      @startup2.balance.should == 5
    end
  end

  describe "Deposit from payment account" do

  end
end
