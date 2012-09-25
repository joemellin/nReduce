require 'spec_helper'

describe WeeklyClass do
  it "should create a current class if none exists" do
    WeeklyClass.count.should == 0
    # It should create a class since one doesn't exist
    current_class = WeeklyClass.current_class
    current_class.should be_valid

    # Make sure it has correct week associated with it
    starts_at = Week.prev_window_for(:join_class).first
    week_integer = Week.integer_for_time(starts_at, :join_class)
    current_class.week.should == week_integer

    # Make sure it only created one class if called again
    WeeklyClass.current_class
    WeeklyClass.count.should == 1

    # If we travel a week ahead it should create another
    Timecop.travel(Time.now + 1.week) do
      next_class = WeeklyClass.current_class
      next_class.should be_valid
      # if at end of year add one year and zero for week
      if week_integer.to_s.size == 6 && week_integer.to_s.last(2) == '53'
        next_week_integer = (week_integer.to_s.first(4).to_i + 1).to_s + '0'
      else # otherwise just add one week
        next_week_integer = week_integer + 1
      end
      next_class.week.should == next_week_integer
    end
  end
end
