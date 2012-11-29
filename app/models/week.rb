class Week
    # Pass in a timestamp and this will return the current week description for that timestamp
  # ex: Jul 5 to Jul 12
  def self.for_time(beginning_of_week)
    end_of_week = beginning_of_week + 6.days
    "#{beginning_of_week.strftime('%B %-d')} to #{end_of_week.strftime('%B %-d')}"
  end

    # returns the week integer for this timestamp, ex: 201223
    # can accomodate time-shifted weeks if you pass in an offset name, ex: :join_class
  def self.integer_for_time(time, offset = nil)
    week = time.strftime("%Y%W").to_i
    return week if offset.blank?
    # subtract one week if we're actually before the week 'starts'
    return Week.previous(week) if (time.beginning_of_week(:sunday) + offset.first) > time
    week
  end

   # Pass in a week integer, ex: 201223, and it will pass back an array of the start time and end time for that week
  def self.window_for_integer(week, offset = nil)
    offset = offset.first unless offset.blank?
    week = week.to_s
    year = week.slice!(0..3)
    return [] if year.blank? || week.blank?
    start_date = Time.parse("#{year}-01-01 00:00:00").beginning_of_week(:sunday)
    start_date += (week.to_i * 7).days
    start_date += offset if offset.present?
    end_date = start_date.end_of_week
    end_date += offset if offset.present?
    [start_date, end_date]
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