require 'spec_helper'

describe Comment do
  before :all do
    @user = FactoryGirl.create(:user, :startup => FactoryGirl.create(:startup))
  end

  it "should allow you to create a new comment on a checkin" do
    checkin = FactoryGirl.create(:completed_checkin)
    checkin.user_id = @user.id
    checkin.save

    user2 = FactoryGirl.create(:user, :email => 'user2@user.com')
    c = Comment.new(:content => "It's incredible how much you were able to accomplish", :checkin_id => checkin)
    c.user = user2
    c.save.should be_true
    c.for_checkin?.should be_true
  end

  it "should allow you to create a new post" do
    c = Comment.new(:content => "nReduce just launched a new feature!")
    c.user = @user
    c.save.should be_true
    c.original_post?.should be_true
  end
end
