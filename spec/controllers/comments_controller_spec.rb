require 'spec_helper'

describe CommentsController do
  login_user_with_startup
  render_views

  before :each do
    @checkin = FactoryGirl.create(:completed_checkin, :startup => @startup)
  end

  it "should allow a user to post a comment" do
    post :create, {:comment => {:content => 'This is just absolutely awesome', :checkin_id => @checkin.id}}, :format => :js
    response.code.should == 200
    response.should render_template(:create)
    assigns(:comment).content.should == 'This is just absolutely awesome'
  end

  it "should allow a user to delete a comment" do
    @comment = FactoryGirl.create(:comment, :checkin => @checkin)
    delete :destroy, {:id => @comment.id}, :format => :js
    response.should render_template(:destroy)
  end

  it "should only allow a comment owner or admin to delete a comment" do
    @user2 = FactoryGirl.create(:user2)
    sign_in @user2
    @comment = FactoryGirl.create(:comment, :checkin => @checkin, :user => @user2)
    delete :destroy, {:id => @comment.id}, :format => :js
    response.code.should == 200
    response.should render_template(:destroy)
  end
end
