require 'spec_helper'

describe RelationshipsController do
  login_user_with_startup

  before :all do
    @startup2 = FactoryGirl.create(:startup2)
  end

  it "should allow a startup to request friendship with another startup" do
    post :create, {:startup_id => @startup2.id}
    assigns(:relationship).should be_valid
    assigns(:relationship).pending?.should be_true
  end

  it "should allow a startup to approve a friendship" do
    r = Relationship.start_between(@startup2, @startup, :startup_startup)
    post :approve, {:id => r.id}
    flash[:notice].should == "You are now connected to #{r.startup.name}."
    response.should redirect_to(relationships_path)
  end

  it "should allow a startup to reject a pending friendship" do
    r = Relationship.start_between(@startup2, @startup, :startup_startup)
    post :reject, {:id => r.id}
    response.should redirect_to(relationships_path)
    flash[:notice].should == "You have rejected a connection with #{r.startup.name}."
  end

  it "should allow a startup to reject an approved friendship" do
    r = Relationship.start_between(@startup2, @startup, :startup_startup)
    r.approve!.should be_true
    post :reject, {:id => r.id}
    response.should redirect_to(relationships_path)
    flash[:notice].should == "You have rejected a connection with #{r.startup.name}."
  end

  it "should not allow a startup to friend themselves" do
    post :create, {:startup_id => @startup.id}
    flash[:alert].should ==  "You aren't allowed to connect with yourself, silly!"
  end

end
