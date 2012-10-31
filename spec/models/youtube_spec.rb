require 'spec_helper'

describe Youtube do
  before :each do
    @youtube = Youtube.new
  end

  it "should allow valid youtube urls" do
    @youtube.youtube_url = 'http://www.youtube.com/watch?v=4vkqBfv8OMM'
    @youtube.valid?
    @youtube.errors[:youtube_url].should be_blank

    @youtube.youtube_url = 'http://youtu.be/Q8FPOcHZSnU'
    @youtube.valid?
    @youtube.errors[:youtube_url].should be_blank

    @youtube.youtube_url = 'http://www.youtube.com/embed/tsh8xvjtalo'
    @youtube.valid?
    @youtube.errors[:youtube_url].should be_blank
  end

  it "should not allow invalid youtube urls" do
    @youtube.youtube_url = 'http://google.com'
    @youtube.valid?
    @youtube.errors.get(:youtube_url).should == ["is not a valid Youtube URL"]

    @youtube.youtube_url = 'http://www.youtube.com/testvideo'
    @youtube.valid?
    @youtube.errors.get(:youtube_url).should == ["is not a valid Youtube URL"]

    @youtube.youtube_url = 'http://youtube.fakeurl.com/watch?v=4vkqBfv8OMM'
    @youtube.valid?
    @youtube.errors.get(:youtube_url).should == ["is not a valid Youtube URL"]
  end
end