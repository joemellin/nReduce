require 'spec_helper'

describe Question do
  before :each do
    @startup = FactoryGirl.create(:startup)
    @user = FactoryGirl.create(:user)
  end

  it "should load all questions for a startup and reset cache when new question is asked" do
    Question.unanswered_for_startup(@startup).should == []

    new_question = Question.create(:content => "How did you pivot so well?", :startup => @startup, :user => @user)

    Question.unanswered_for_startup(@startup).should == [new_question]
  end

  it "should recognize user as supporter and change last changed at" do
    last_changed_at = Question.last_changed_at_for_startup(@startup)
    sleep 1
    @question = Question.new(:content => "How did you come up with that business model?", :startup => @startup, :user => @user)
    user2 = FactoryGirl.create(:user2)
    @question.add_supporter!(user2)
    @question.reload
    @question.supporters.should include user2
    @question.is_supporter?(user2).should == true
    Question.last_changed_at_for_startup(@startup).should be > last_changed_at
  end
end