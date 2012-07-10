require 'spec_helper'

describe ActsAsTaggableOn::Tag do
  # Testing my add-on to search for multiple tags from a commma separated string
  it "should find multiple tags from a string" do
    ['Mobile Applications', 'big-Data'].each do |tag_name|
      t = ActsAsTaggableOn::Tag.new
      t.name = tag_name
      t.save
    end
    ActsAsTaggableOn::Tag.named_like_any_from_string('mobile applications, ').size.should == 1
    ActsAsTaggableOn::Tag.named_like_any_from_string('mobile applications, big data').size.should == 2
  end
end
