class Stats
  
    # Calculate engagement metrics for all users
    # Simply calculates avg number of comments given per startup per week
    # @from_time (start metrics on this date)
    # @to_time (optional - end metrics on this date, defaults to now)
  def self.calculate_engagement_metrics(from_time = nil, to_time = nil, dont_save = false, max_comments_per_checkin = 2)
    from_time ||= Time.now - 4.weeks
    to_time ||= Time.now
    return 'From time is not after to time' if from_time > to_time

    # Grab all comments that everyone created during the time period
    comments_by_user = Hash.by_key(Comment.where(['created_at > ? AND created_at < ?', from_time.to_s(:db), to_time.to_s(:db)]).all, :user_id, nil, true)

    # Grab all completed checkins completed during this time period to see how many you did/ didn't comment on
    checkins_by_startup = Hash.by_key(Checkin.where(['created_at > ? AND created_at < ?', from_time.to_s(:db), to_time.to_s(:db)]).completed.all, :startup_id, nil, true)

    # Looping through all startups
    #
    # Cheating a bit here - really should see who you're connected to each week, as it penalizes you for adding new connections after the commenting window is open
    results = {}
    Startup.includes(:team_members).onboarded.all.each do |startup|
      num_for_startup = num_checkins = 0
      results[startup.id] = {}
      results[startup.id][:total] = nil

      checkins_by_this_startup = Hash.by_key(checkins_by_startup[startup.id], :id)

      # How many checkins did your connected startups make?
      startup_ids = Relationship.all_connection_ids_for(startup)['Startup']
      unless startup_ids.blank?
        startup_ids.map do |startup_id|
          num_checkins += checkins_by_startup[startup_id].size unless checkins_by_startup[startup_id].blank?
        end
      end

      startup.team_members.each do |user|
        rating = nil

        # Skip if their connections haven't made any checkins
        if num_checkins > 0
          num_comments_by_user = 0
          # What is total number of comments on these checkins?
          # - ignore comments on your own checkins
          # - max 2 comments per checkin are counted
          unless comments_by_user[user.id].blank?
            comments_by_checkin_id = Hash.by_key(comments_by_user[user.id], :checkin_id, nil, true)
            comments_by_checkin_id.each do |checkin_id, comments|
              # skip if this is one of their checkins
              next unless checkins_by_this_startup[checkin_id].blank?

              # limit count to max comments per checkin number
              num_comments_by_user += (comments.size > max_comments_per_checkin ? max_comments_per_checkin : comments.size)
            end
          end
          
          rating = (num_comments_by_user.to_f / num_checkins.to_f).round(3)
          num_for_startup += rating
        end
        user.rating = rating
        user.save(:validate => false) unless dont_save
        results[startup.id][user.id] = rating
      end

      # calculate after for startup
      rating = nil
      rating = num_for_startup.to_f.round(3) unless num_checkins == 0
      startup.rating = rating
      startup.save(:validate => false) unless dont_save
      results[startup.id][:total] = rating
    end
    results
  end
end