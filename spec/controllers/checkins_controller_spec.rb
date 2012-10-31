require 'spec_helper'

describe CheckinsController do
  # sign in with devise macro
  login_user_with_startup

  describe "new checkin" do
    it "should not allow a user without a current startup to post a checkin" do
      @user.update_attribute('startup', nil)
      get :new
      response.should redirect_to(new_startup_path)
    end

    it "should allow a user to start a check-in between Monday at 4pm PST and Tuesday at 4pm PST" do
      Timecop.freeze(Time.now.beginning_of_week + 17.hours) do
        get :new
        assigns(:checkin).should be_a(Checkin)
        response.should render_template(:edit)
      end
      Timecop.freeze(Time.now.beginning_of_week + 1.day + 15.hours) do
        get :new
        assigns(:checkin).should be_a(Checkin)
        response.should render_template(:edit)
      end
    end

    it "should not allow a user to checkin outside of Monday at 4pm PST and Tuesday at 4pm PST" do
      Timecop.freeze(Time.now.beginning_of_week + 15.hours) do
        get :new
        response.should redirect_to(checkins_path)
        flash[:alert].should == "Sorry you've missed the 'before' check-in time."
      end
      Timecop.freeze(Time.now.beginning_of_week + 1.day + 17.hours) do
        get :new
        response.should redirect_to(checkins_path)
        flash[:alert].should == "Sorry you've missed the 'before' check-in time."
      end
    end
  end

  describe "show checkin" do
    it "should only allow a user and their connected relationships to view a checkin" do
      pending
    end
  end

  describe "edit checkin" do

    it "should allow a user to complete a check-in between Tuesday at 4pm PST and Wednesday at 4pm PST" do
      @checkin = FactoryGirl.create(:submitted_checkin, :startup => @startup)

      Timecop.freeze(Time.now.beginning_of_week + 2.days + 17.hours) do
        get :edit, :id => @checkin.id
        response.should render_template(:edit)
        assigns(:checkin).should be_a(Checkin)
      end

      Timecop.freeze(Time.now.beginning_of_week + 3.days + 15.hours) do
        get :edit, :id => @checkin.id
        response.should render_template(:edit)
        assigns(:checkin).should be_a(Checkin)
      end
    end

    it "should not allow a user to complete a check-in outside of Tuesday at 4pm PST and Wednesday at 4pm PST" do
      @checkin = FactoryGirl.create(:submitted_checkin, :startup => @startup)

      Timecop.freeze(Time.now.beginning_of_week + 3.days + 17.hours) do
        get :edit, :id => @checkin.id
        response.should redirect_to('/')
        flash[:alert].should == "You aren't within the 'after' check-in time window."
      end
    end
  end
end
