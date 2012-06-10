class Week
  # Returns the ID used for a week with this timestamp
  # YYYYW (w being the week of the year)
  def self.id_for_time(timestamp)
    "#{timestamp.year}#{timestamp.strftime('%W')}".to_i
  end

  # Pass in a Week id, ex: 20125 (2012 week 5)
  # Returns the week name (pass true to show year to also have year)
  def self.name_for_id(week_id, show_year = false)
    "Week #{week_id.to_s[4,week_id.to_s.size - 1]}#{show_year ? ', 2012' : ''}"
  end
end