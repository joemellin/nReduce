require 'spec_helper'

describe Request do
  before :each do
    @startup = FactoryGirl.create(:startup)
    @user = FactoryGirl.create(:user, :startup => @startup)
    @account = Account.create_for_owner(@startup)
    @ui_ux_request = FactoryGirl.build(:ui_ux_request, :startup => @startup, :user => @user)
  end

  describe "setting up a request" do
    it "should allow us to create different request types" do
      @account.balance = 10
      @account.save

      @ui_ux_request.save.should be_true

      @startup.balance.should == 0
      @startup.escrow.should == 10
    end

    it "should require enough helpfuls - and transfer them to escrow" do
      @account.balance = 1
      @account.save

      @ui_ux_request.save.should be_false
      @ui_ux_request.errors[:startup].count.should == 1

      @startup.balance.should == 1
      @startup.escrow.should == 0
    end

    it "should check for filled out data" do
      @ui_ux_request.data = ['test', "won't work"]
      @ui_ux_request.save.should be_false
      @ui_ux_request.errors[:data].count.should == 1
    end

    it "should allow other request types" do
      @account.balance = 2
      @account.save
      @retweet = @ui_ux_request
      @retweet.request_type = :retweet
      @retweet.data = ['https://twitter.com/statuses/1231231']
      @retweet.save.should be_true

      @hn_upvote = @ui_ux_request
      @hn_upvote.request_type = :hn_upvote
      @hn_upvote.data = ['http://news.ycombinator.com/link']

      # first test not enough balance for this
      @account.balance = 2
      @account.save

      @hn_upvote.save.should be_false

      @hn_upvote = @ui_ux_request
      @hn_upvote.request_type = :hn_upvote
      @hn_upvote.data = ['http://news.ycombinator.com/link']

      @account.balance = 4
      @account.save

      @hn_upvote.save.should be_true
    end
  end

  describe "closing a request to new participants" do
    it "should close request if no started responses" do
      @account.balance = 10
      @account.save
      @ui_ux_request.save

      @ui_ux_request.close!

      @ui_ux_request.closed?.should be_true
    end

    it "shouldn't close a request if there are responses started" do
      @account.balance = 10
      @account.save 
      @ui_ux_request.save

      response = Response.new
      response.request = @ui_ux_request
      response.user = FactoryGirl.create(:user2, :roles => [])

      @ui_ux_request.close!
      @ui_ux_request.closed?.should be_true
    end
  end
end