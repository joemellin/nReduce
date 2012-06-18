require 'spec_helper'

describe Checkin do
  before :all do
    @user = FactoryGirl.create(:user)
    @checkin = Checkin.new
    @checkin.user_id = @user.id
    @checkin.startup = FactoryGirl.create(:startup)
    @checkin.start_focus = 'Make awesome happen'
    @valid_youtube_url = 'http://www.youtube.com/watch?v=4vkqBfv8OMM'
  end

  it "should allow valid youtube urls" do
    @checkin.start_video_url = 'http://www.youtube.com/watch?v=4vkqBfv8OMM'
    @checkin.errors[:start_video_url].should be_blank

    @checkin.start_video_url = 'http://youtu.be/Q8FPOcHZSnU'
    @checkin.errors[:start_video_url].should be_blank

    @checkin.start_video_url = 'http://www.youtube.com/embed/tsh8xvjtalo'
    @checkin.errors[:start_video_url].should be_blank
  end

  it "should not allow invalid youtube urls" do
    @checkin.start_video_url = 'http://google.com'
    @checkin.valid?
    @checkin.errors.get(:start_video_url).should == ["invalid Youtube URL"]

    @checkin.start_video_url = 'http://www.youtube.com/testvideo'
    @checkin.valid?
    @checkin.errors.get(:start_video_url).should == ["invalid Youtube URL"]

    @checkin.start_video_url = 'http://youtube.fakeurl.com/watch?v=4vkqBfv8OMM'
    @checkin.valid?
    @checkin.errors.get(:start_video_url).should == ["invalid Youtube URL"]
  end

  it "should never change the timestamp on submitted at date" do
    @checkin.start_video_url = @valid_youtube_url
    @checkin.valid?
    @checkin.errors.inspect
    @checkin.save.should be_true

    submitted_at = @checkin.submitted_at
    # Make sure submitted as isn't nil
    submitted_at.should_not be_nil

    # Assign new video
    @checkin.start_video_url = 'http://youtu.be/Q8FPOcHZSnU'
    @checkin.save

    @checkin.submitted_at.should == submitted_at
  end

  it "should never change the timestamp on completed at date" do
    @checkin.start_video_url = @valid_youtube_url
    @checkin.end_video_url = @valid_youtube_url
    @checkin.end_comments = 'Made it happen!'
    @checkin.save.should be_true

    completed_at = @checkin.completed_at
    @checkin.end_video_url = 'http://www.youtube.com/watch?v=R72kxEmB3EE&feature=g-logo-xit'
    @checkin.save.should be_true

    @checkin.completed_at.should == completed_at
  end

  it "should return the next checkin is a before checkin at tuesday at 4pm if it's Monday" do
    Timecop.freeze(Time.now.beginning_of_week + 12.hours) do
      Checkin.next_checkin_type_and_time.should == {:type => :before, :time => Time.now + 1.day + 4.hours}
    end
  end

  it "should return the next checkin is an after checkin at Wednesday at 4pm if it's Tuesday at 8pm" do
    Timecop.freeze(Time.now.beginning_of_week + 1.day + 20.hours) do
      Checkin.next_checkin_type_and_time.should == {:type => :after, :time => Time.now + 20.hours}
    end
  end

  it "should return the next checkin is a before checkin if it's Wednesday at 5pm" do
    Timecop.freeze(Time.now.beginning_of_week + 2.days + 17.hours) do
      Checkin.next_checkin_type_and_time.should == {:type => :before, :time => Time.now.beginning_of_week + 1.week + 1.day + 16.hours}
    end
  end

  it "should notify this startup's relationships when they complete a checkin" do
    pending
  end
end
