require 'spec_helper'

describe Checkin do
  before :each do
    # Startup must be created for user so user can be team member on startup
    @startup = FactoryGirl.build(:startup)
    @user = FactoryGirl.create(:user, :startup => @startup)
    @checkin = Checkin.new
    @checkin.user_id = @user.id
    @checkin.startup = @startup
    @checkin.goal = 'Make awesome happen'
    @checkin.before_video = Youtube.new(:youtube_url => 'http://www.youtube.com/watch?v=4vkqBfv8OMM')
    @valid_youtube_url = 'http://www.youtube.com/watch?v=4vkq0w0s1MM'
  end

  it "should never change the timestamp on submitted at date" do
    @checkin.save.should be_true

    submitted_at = @checkin.submitted_at
    # Make sure submitted as isn't nil
    submitted_at.should_not be_nil

    # Assign new video
    @checkin.before_video = Youtube.new(:youtube_url => 'http://youtu.be/Q8FPOcHZSnU')
    @checkin.save

    @checkin.submitted_at.should == submitted_at
  end

  it "should never change the timestamp on completed at date" do
    @checkin.video = Youtube.new(:youtube_url => @valid_youtube_url)
    @checkin.notes = 'Made it happen!'
    @checkin.save.should be_true

    completed_at = @checkin.completed_at
    @checkin.video = Youtube.new(:youtube_url => 'http://www.youtube.com/watch?v=R72kxEmB3EE&feature=g-logo-xit')
    @checkin.save.should be_true

    @checkin.completed_at.should == completed_at
  end

  it "should reset current checkin cache when new checkin is created" do
    @checkin.video = Youtube.new(:youtube_url => @valid_youtube_url)
    @checkin.notes = 'Made it happen!'
    @checkin.created_at = Checkin.prev_after_checkin + 2.days
    puts @checkin.save
    puts @checkin.inspect

    # No idea why, but the checkin successfully saves above, but when I try to reload it, the record doesn't exist
    @checkin.reload
    
    @checkin.startup.current_checkin.should == @checkin

    Timecop.travel(Checkin.next_window_for(:after_checkin).first + 10.minutes) do
      checkin2 = FactoryGirl.create(:completed_checkin, 
        :startup => @checkin.startup, 
        :before_video => Youtube.new(:youtube_url => 'http://www.youtube.com/watch?v=1230fdsanE'),
        :video => Youtube.new(:youtube_url => 'http://www.youtube.com/watch?v=R723840sdfxE')
      )
      checkin2.valid?
      checkin2.save.should == true
      checkin2.startup.current_checkin.should == checkin2
    end
  end

  it "should return the next checkin is an after checkin at tuesday at 4pm if it's Monday" do
    Timecop.freeze(Time.now.beginning_of_week + 12.hours) do
      Checkin.next_checkin_type_and_time.should == {:type => :after, :time => Time.now + 1.day + 4.hours}
    end
  end

  it "should return the next checkin is a before checkin at Wednesday at 4pm if it's Tuesday at 8pm" do
    Timecop.freeze(Time.now.beginning_of_week + 1.day + 20.hours) do
      Checkin.next_checkin_type_and_time.should == {:type => :before, :time => Time.now + 20.hours}
    end
  end

  it "should return the next checkin is an after checkin if it's Wednesday at 5pm" do
    Timecop.freeze(Time.now.beginning_of_week + 2.days + 17.hours) do
      Checkin.next_checkin_type_and_time.should == {:type => :after, :time => Time.now.beginning_of_week + 1.week + 1.day + 16.hours}
    end
  end

  it "should notify this startup's relationships when they complete a checkin" do
    startup2 = FactoryGirl.build(:startup2)
    user2 = FactoryGirl.create(:user2, :startup => startup2)
    startup2.reload
    puts startup2.team_members.inspect
    r = Relationship.start_between(@startup, startup2)
    r.approve!
    @checkin.save

    puts Notification.create_for_new_checkin(@checkin)
  end
end
