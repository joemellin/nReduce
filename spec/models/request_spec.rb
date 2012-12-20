require 'spec_helper'

describe Request do

  # Note: request prices are set in settings.yml (request_prices)

  before :each do
    @startup = FactoryGirl.create(:startup)
    @user = FactoryGirl.create(:user, :startup => @startup)
    @account = Account.create_for_owner(@startup)
    @ui_ux_request = FactoryGirl.build(:usability_test_request, :startup => @startup, :user => @user)
    @retweet_request = FactoryGirl.build(:retweet_request, :startup => @startup, :user => @user)
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
      @ui_ux_request.data = {'test' => 'test'}
      @ui_ux_request.save.should be_false
      @ui_ux_request.errors[:data].count.should == 1
    end

    it "should allow a hash for data from the form" do
      data = {}
      c = 0
      first_key = nil
      @ui_ux_request.questions.each do |k,v|
        data[k] = "Another response #{c}"
        c += 1
        first_key ||= k
      end
      @ui_ux_request.data = data
      @ui_ux_request.data[first_key].should == "Another response 0"
      @ui_ux_request.valid?
      @ui_ux_request.errors[:data].count.should == 0
    end

    it "should allow other request types" do
      @account.balance = 2
      @account.save

      @retweet_request.data = {'url' => 'https://twitter.com/statuses/1231231'}
      @retweet_request.num = 4
       # first test not enough balance for this
      @retweet_request.save.should be_false

      # now up the balance
      @account.balance = 5
      @account.save.should be_true

      @retweet_request.save.should be_true
    end

    it "should allow users to earn more points if they have more followers" do
      @user.followers_count = 80
      @retweet_request.num = 5
      @retweet_request.data = {'url' => 'https://twitter.com/statuses/1231231'}
      @retweet_request.save

      # shouldn't be able to earn anything if they don't have enough followers
      @retweet_request.user_can_earn(@user).should == 0

      @user.followers_count = 500
      @retweet_request.user_can_earn(@user).should == 5

      # Shouldn't be able to earn more than max # user is willing to pay
      @user.followers_count = 10000
      @retweet_request.user_can_earn(@user).should == 5
    end
  end

  describe "canceling a request" do
    it "should cancel a request and delete if no responses" do
      @account.balance = 10
      @account.save
      @ui_ux_request.save.should be_true
      id = @ui_ux_request.id
      @ui_ux_request.cancel!.should be_true

      Request.exists?(id).should be_false
      @account.reload.balance.should == 10
      @account.escrow.should == 0
    end

    it "should close a request if there have been responses" do
      @account.balance = 10
      @account.save
      @ui_ux_request.save.should be_true

      response = Response.new
      response.request = @ui_ux_request
      response.user = FactoryGirl.create(:user2, :roles => [])
      response.save

      @ui_ux_request.cancel!.should be_true
      Request.exists?(@ui_ux_request.id).should be_true

      @account.reload
      @account.balance.should == 5 # total amount - 1 response
      @account.escrow.should == 5 # still waiting for other response to complete
    end
  end
end