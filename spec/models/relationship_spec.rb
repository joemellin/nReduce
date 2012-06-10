require 'spec_helper'

describe Relationship do
  before :all do
    @startup1 = FactoryGirl.create(:startup)
    @startup2 = FactoryGirl.create(:startup, :name => 'Facebook for Ferrets')
  end

  before :each do
    @relationship = Relationship.start_between(@startup1, @startup2)
  end

  it "should add a startup in a relationship" do
    @relationship.pending?.should be_true
  end

  it "should approve a startup in a relationship" do
    @relationship.approve!
    Relationship.where(:startup_id => @startup1.id, :connected_with_id => @startup2.id, :status => Relationship::APPROVED).count.should == 1
    @startup1.connected_to?(@startup2).should be_true
  end

  it "should reject a startup in a relationship" do
    @relationship.reject!
    @startup1.connected_to?(@startup2).should be_false
  end
end
