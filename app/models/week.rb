class Week
  # THIS IS REALLY A DIFFERENT CLASS - TIME WINDOWS
  
  def self.time_windows
    {
      # type => [offset from beginning of week, length]
      :after_checkin => [1.day + 16.hours, 24.hours],
      :before_checkin => [2.days + 16.hours, 24.hours],
      :join_class => [2.days + 12.hours, 2.hours]
    }
  end

     # Returns true if time given is in the time window. If no time given, defaults to now
  def self.in_time_window?(type, time = nil)
    time ||= Time.now
    next_window = Week.next_window_for(type, true)
    return true if time > next_window.first && time < next_window.last
    false
  end

    # Returns array of [start_time, end_time] for this type
  def self.next_window_for(type, dont_skip_if_in_window = false)
    t = Time.now
    beginning_of_week = t.beginning_of_week
    window_info = Week.time_windows[type]
    window_start = beginning_of_week + window_info.first
    # We're after the beginning of this time window, so add a week unless we're suppressing that
    window_start += 1.week if (t > window_start) && !dont_skip_if_in_window
    [window_start, window_start + window_info.last]
  end

  def self.prev_window_for(type)
    Week.next_window_for(type).map{|t| t - 1.week }
  end

  # Returns string description of the next time window for this type, ex: Jul 5 to Jul 12 for next class
  def self.desc_for_next_of_type(type)
    Week.for_time(Week.next_window_for(type).first)
  end

  # WEEK STUFF

    # Pass in a timestamp and this will return the current week description for that timestamp
  # ex: Jul 5 to Jul 12
  def self.for_time(beginning_of_week)
    end_of_week = beginning_of_week + 6.days
    "#{beginning_of_week.strftime('%b %-d')}-#{end_of_week.strftime('%b %-d')}"
  end

    # returns the week integer for this timestamp, ex: 201223
  def self.integer_for_time(time)
    time.strftime("%Y%W").to_i
  end

  # Pass in a week integer (ex: 20126) and this will pass back the week before, 20125
  # accounts for changes in years
  def self.previous(week)
    # see if we're at the end of a year
    s = week.to_s
    # If passing in 2012, zerofill with one zero so it's the right length
    if s.size == 4
      week = "#{week}0".to_i 
      s = week.to_s
    end
    if s.size == 5 and s.last == '0'
      return ((s.first(4).to_i - 1).to_s + '53').to_i
    else
      return week - 1
    end
  end

end