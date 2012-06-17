require 'spec_helper'

describe MeetingMessage do
  it "should message attendees when created" do
    @meeting = FactoryGirl.create(:meeting)
    mm = MeetingMessage.new(:subject => 'You guys better come!', :body => 'I have awesome beer and pizza arranged if you make it at 7pm')
    mm.meeting = @meeting
    mm.user = @meeting.organizer
    mm.save.should be_true
  end
end
