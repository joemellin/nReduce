class Week

  scope :for_time, ->(t){ where(:start_date.lt => t, :end_date.gt => t) }

    # Generates a series of 12 weeks for a specific batch
  def self.generate_starting_on(date, batch, num = 12, time = '16:00')
    return 'Weeks already exist for this batch' if batch.weeks.count > 0
    t = Time.parse("#{date.to_s} #{time}")
    1.upto(12).each do |i|
      Week.create(:name => i, :start_date => t, :end_date => (t + 1.week - 1.second), :batch => batch)
      t += 1.week
    end
  end