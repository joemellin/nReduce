require 'spec_helper'

describe AwesomesController do
  login_user_with_startup

  before :each do
    @startup2 = FactoryGirl.create(:startup2)
    @checkin = FactoryGirl.create(:submitted_checkin, :startup => @startup2)
  end

  it "should allow you to awesome someone else's checkin" do
    post :create, {:checkin_id => @checkin.id}, :format => :js
    response.code.should == '302'
    response.should redirect_to('/')
  end

  it "should allow you to change your mind should you think someone else's checkin is no longer awesome" do
    a = FactoryGirl.create(:awesome, :startup => @startup2)
    delete :destroy, {:id => a.id}, :format => :js
    response.code.should == '302'
    response.should redirect_to('/')
  end

  it "should not allow you to awesome your own checkin" do
    pending
  end
end
