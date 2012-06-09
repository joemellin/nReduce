class Week
  # Returns the ID used for a week with this timestamp
  # YYYYW (w being the week of the year)
  def self.id_for_time(timestamp)
    "#{timestamp.year}#{timestamp.strftime('%W')}".to_i
  end

  def self.name_for_id(week_id)
    week_id.to_s.substr(4,week_id.to_s.size)
  end
end