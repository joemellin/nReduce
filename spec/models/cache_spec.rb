require 'spec_helper'

describe Cache do
  it "should create cache keys correctly" do
    str = "string"
    obj = FactoryGirl.create(:meeting)
    Cache.key_for([str, obj]).should == 'string_meeting_' + obj.id.to_s
  end
end
