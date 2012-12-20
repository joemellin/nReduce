require 'spec_helper'

describe Response do
  before :each do
    $redis.flushall # had problems with accounts being cached
    @startup = FactoryGirl.create(:startup)
    @startup2 = FactoryGirl.create(:startup2)
    @user = FactoryGirl.create(:user, :startup => @startup)
    @user2 = FactoryGirl.create(:user2, :startup => @startup2)
    @account = Account.create_for_owner(@startup)
    @account.balance = 10
    @account.save
    @account2 = Account.create_for_owner(@startup2)
    @ui_ux_request = FactoryGirl.create(:usability_test_request, :startup => @startup, :user => @user)
    @retweet_request = FactoryGirl.build(:retweet_request, :startup => @startup, :user => @user)

    @response = Response.new
    @response.request = @ui_ux_request
    @response.user = @user2
    @response_data = {}
    @response.questions.each do |k,v|
      @response_data[k] = 'Sample Response'
    end
  end

  describe "responding to a request" do
    it "should allow you to respond to a request and reduce # of open slots on request" do
      prev_num = @ui_ux_request.num
      @response.save.should be_true
      @response.started?.should be_true
      @ui_ux_request.reload
      @ui_ux_request.num.should == prev_num - 1
    end

    it "should allow the responder to complete a request" do
      @response.save
      @response.data = @response_data
      @response.complete!.should be_true
      @response.status.should == [:completed]
    end

    it "should allow the responder to cancel a response" do
      @response.save
      @response.cancel!.should be_true
      @response.status.should == [:canceled]
      @response.canceled?.should be_true
    end

    it "should allow the requestor to approve a request and pay responder" do
      @account2.balance.should == 0
      @account.reload
      @account.escrow.should == 10
      @response.save
      prev_num = @ui_ux_request.reload.num

      # Complete & accept request
      @response.data = @response_data
      @response.complete!.should be_true
      @response.accept!.should be_true
      @response.status.should == [:accepted]

      # Number of people shouldn't change - already removed
      @ui_ux_request.reload
      @ui_ux_request.num.should == prev_num
      @account.reload
      @account2.reload

      # User should be paid
      @account.escrow.should == 5
      @account2.balance.should == 5
    end

    it "should adjust payment for tasks that a user can earn more - like retweets" do
      # have to re-up the balance because it is put into escrow when ui_ux_request is created
      @startup.account.balance = 10
      @startup.account.escrow = 0
      @startup.account.save

      # having problems with account balance being cached... need to make sure this isn't a problem in production on stale balances
      @retweet = FactoryGirl.build(:retweet_request, :startup => @startup, :user => @user, :num => 5)
      @retweet.save.should be_true

      @user2.followers_count = 430
      @user2.save

      @response = Response.new
      @response.user = @user2
      @response.request = @retweet
      @response.save
      @response.complete!.should be_true
      # it should be auto-accepted for a retweet
      @response.accepted?.should be_true

      @retweet.reload
      @response.amount_paid.should == 4
      @retweet.num.should == 1
    end

    it "should allow the requestor to reject a request" do
      prev_num = @ui_ux_request.reload.num
      @response.save
      @response.data = @response_data
      @response.complete!.should be_true
      @response.reject!("I didn't see you actually load the website").should be_true
      @response.status.should == [:rejected]
      @ui_ux_request.reload
      @ui_ux_request.num.should == prev_num
    end

    it "should allow the system to expire an incompleted request" do
      prev_num = @ui_ux_request.num
      @response.save # start request but don't complete it
      @response.expire!.should be_true
      @response.status.should == [:expired]
      @ui_ux_request.reload
      @ui_ux_request.num.should == prev_num
    end

    it "shouldn't allow the system to expire a completed request" do
      @response.save
      @response.data = @response_data
      @response.complete!.should be_true
      @response.expire!.should be_false
      @response.status.should == [:completed]
      @response.expired_at.should be_nil
    end

    it "shouldn't allow user who started request to complete it" do
      @response.user = @user
      @response.save.should be_false
    end
  end

  describe "expiring responses" do
    it "should expire if the response is old" do
      @response.save
      # More than 60 minutes for ui/ux requests
      Timecop.freeze(Time.now + 2.hours) do
        @response.should_be_expired?.should be_true
      end

      # use retweet request - which is 30 minutes

      @account.balance = 1
      @account.save
      @retweet_request.num = 1
      @retweet_request.data = {'url' => 'test'}
      @retweet_request.save.should be_true
      @response.request = @retweet_request
      @response.save
      @response.reload

      Timecop.freeze(Time.now + 35.minutes) do
        @retweet_request.num.should == 0
        @response.should_be_expired?.should be_true
        @response.expire!
        @retweet_request.reload.num.should == 1
      end
    end

    it "shouldn't be expire if not yet passed threshold" do
      @response.save
      # Try moving just 5 minutes in future
      Timecop.freeze(Time.now + 5.minutes) do
        @response.should_be_expired?.should be_false
      end
      # or in the past
      Timecop.freeze(Time.now - 10.minutes) do
        @response.should_be_expired?.should be_false
      end
    end
  end
end