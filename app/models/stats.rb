class Stats
  
    # Calculate engagement metrics for all users
    # Limitations:
    # - doesn't account for when team members are added, so they will get penalized if added
    # - doesn't calculate metrics for mentors or investors
    # Calculates avg number of comments given per checkin seen by each user per week
    # Writes data to rating attribute on user and startup
    # @from_time (start metrics on this date) - this is changed to be at the beginning of checkin time, because otherwise the results are skewed if in the middle of a checkin period
    # @to_time (optional - end metrics on this date, defaults to now)
  def self.calculate_engagement_metrics(from_time = nil, to_time = nil, dont_save = false, max_comments_per_checkin = 2)
    from_time ||= Time.now - 4.weeks
    from_time = Checkin.week_start_for_time(from_time)
    to_time ||= Time.now
    return 'From time is not after to time' if from_time > to_time

    # Grab all comments that everyone created during the time period
    comments_by_user = Hash.by_key(Comment.where(['created_at > ? AND created_at < ?', from_time.to_s(:db), to_time.to_s(:db)]).all, :user_id, nil, true)

    # Grab all completed checkins completed during this time period to see how many you did/ didn't comment on
    checkins_by_startup = Hash.by_key(Checkin.where(['created_at > ? AND created_at < ?', from_time.to_s(:db), to_time.to_s(:db)]).completed.all, :startup_id, nil, true)

    # Looping through all startups
    #
    results = {}
    Startup.includes(:team_members).all.each do |startup|
      num_for_startup = 0.0
      results[startup.id] = {}
      results[startup.id][:total] = nil

      # All the checkins this startup has completed by id
      checkins_by_this_startup = Hash.by_key(checkins_by_startup[startup.id], :id)

      # Need to figure out when a startup was connected to other startups so we only count checkins they saw
      # Since relationships have inverse, this will get both
      relationships = Relationship.history_for_entity(startup, 'Startup')

      # Skip if they're not connected to anyone
      next if relationships.blank? or relationships['Startup'].blank?
      # Only use startup relationships
      relationships = relationships['Startup']

      # Gather all startup ids that this startup was connected to
      startup_ids = relationships.keys

      valid_checkin_ids = []
      # How many checkins did your connected startups make?
      startup_ids.map do |startup_id|
        # iterate through checkins and see if they were connected at that time. If so add to num checkins seen
        next if checkins_by_startup[startup_id].blank?
        checkins_by_startup[startup_id].each do |c|
          # relationships is array of [approved at Time, rejected at Time (or current time if not rejected)]
          if relationships[startup_id].first <= c.completed_at && relationships[startup_id].last >= c.completed_at
            valid_checkin_ids << c.id
          end
        end
      end

      # Iterate through each team member and calculate engagement metrics
      startup.team_members.each do |user|
        rating = nil

        # Skip if their connections haven't made any checkins
        unless valid_checkin_ids.blank?
          num_comments_by_user = 0
          # What is total number of comments by this user on the checkins seen?
          # - ignore comments on your own checkins
          # - max 2 comments per checkin are counted
          unless comments_by_user[user.id].blank?
            # Key comments by checkin id so we can see how many the user made per checkin
            comments_by_checkin_id = Hash.by_key(comments_by_user[user.id], :checkin_id, nil, true)
            comments_by_checkin_id.each do |checkin_id, comments|
              # skip if they weren't connected or this was one of their checkins
              next unless valid_checkin_ids.include?(checkin_id)

              # limit count to max comments per checkin number
              num_comments_by_user += (comments.size > max_comments_per_checkin ? max_comments_per_checkin : comments.size)
            end
          end
          rating = (num_comments_by_user.to_f / valid_checkin_ids.size.to_f).round(3)
          num_for_startup += rating
        end
        # Save user's rating and add to startup's rating
        user.rating = rating
        user.save(:validate => false) unless dont_save
        results[startup.id][user.id] = rating
      end

      # calculate after for startup
      rating = nil
      rating = num_for_startup.round(3) unless valid_checkin_ids.blank?
      startup.rating = rating
      startup.save(:validate => false) unless dont_save
      results[startup.id][:total] = rating
    end
    results
  end
end