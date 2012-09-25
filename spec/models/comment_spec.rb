require 'spec_helper'

describe Comment do
  before :each do
    @user = FactoryGirl.create(:user, :startup => FactoryGirl.create(:startup))

    @checkin = FactoryGirl.create(:completed_checkin, :startup => @user.startup)
    @checkin.user_id = @user.id
    @checkin.save
  end

  it "should allow you to create a new comment on a checkin" do
    user2 = FactoryGirl.create(:user, :email => 'user2@user.com')
    c = Comment.new(:content => "It's incredible how much you were able to accomplish", :checkin_id => @checkin.id)
    c.user = user2
    c.save.should be_true
    c.for_checkin?.should be_true

    notification = c.notifications.first
    # Deliver email notification of comment
    Notification.perform(notification.id).should be_true
  end

  it "shouldn't allow you to delete a comment that has children" do
    c = Comment.new(:content => "Isn't San Francisco so hipster?", :checkin_id => @checkin.id)
    c.user = @user
    c.save.should be_true

    c2 = Comment.new(:content => "Absolutely, it's like its been invaded by Portlandia", :checkin_id => @checkin.id, :parent_id => c.id)
    c2.user = @user
    c2.save.should be_true

    c.safe_destroy
    Comment.exists?(c.id).should be_true
    Comment.find(c.id).deleted?.should be_true
  end

  it "should allow you to create a new post and comment on the post" do
    c = Comment.new(:content => "nReduce just launched a new feature!")
    c.user = @user
    c.save.should be_true
    c.original_post?.should be_true

    user2 = FactoryGirl.create(:user, :email => 'user2@user.com')
    c2 = Comment.new(:content => "Wow that's incredible!", :parent_id => c.id)
    c2.user = user2
    c2.save.should be_true
    c2.for_post?.should be_true
    notification = c2.notifications.first

    # Deliver email notification post comment
    Notification.perform(notification.id).should be_true
  end
end
