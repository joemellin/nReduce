class Stats

  # Returns the ids of checkins that this user has seen during the given time period
  # It will check for direct relationships (mentor -> startup), as well as user's startup -> startups
  # It will also ignore any checkins created by this user's startup
  # def self.checkin_ids_seen(from_time, to_time, checkins_by_startup = [])
  #   # Grab all completed checkins completed during this time period to see how many you did/ didn't comment on
  #   checkins_by_startup ||= Hash.by_key(Checkin.where(['created_at > ? AND created_at < ?', from_time.to_s(:db), to_time.to_s(:db)]).completed.all, :startup_id, nil, true)

  #   if self.entrepreneur? and !self.startup.blank?
  #     user_relationship_history = Relationship.history_for_entity(self.startup, 'Startup')
  #   end
  #   user_relationship_history

  #   user_relationship_history = Relationship.history_for_entity(self.startup)
  # end
  
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

  def self.checkins_per_week_for_chart(since = 10.weeks)
    Checkin.group(:week).where(['created_at > ?', Time.now - since]).order(:week).count.map{|week, num| OpenStruct.new(:key => week, :value => num) }
  end

  def self.comments_per_week_for_chart(since = 10.weeks)
    c_by_w = {}
    Comment.where(['created_at > ?', Time.now - since]).each do |c| 
      week = Week.integer_for_time(c.created_at, :before_checkin)
      c_by_w[week] ||= 0
      c_by_w[week] += 1
    end
    c_by_w.sort.map{|arr| OpenStruct.new(:key => arr.first, :value => arr.last) }
  end

  def self.startups_activated_per_week_for_chart(since = 10.weeks)
    date_start = Time.now - since
    a_by_w = {}
    current = Week.integer_for_time(Time.now)
    last = Week.integer_for_time(date_start)
    while current > last
      a_by_w[current] = 0
      current = Week.previous(current)
    end
    c_by_s = Hash.by_key(Checkin.order('created_at ASC').all, :startup_id, nil, true)
    c_by_s.each do |startup_id, checkins|
      # Skip unless their first checkin was after the date limit
      next unless checkins.first.time_window.first > date_start
      a_by_w[checkins.first.week] += 1
    end
    a_by_w.sort.map{|arr| OpenStruct.new(:key => arr.first, :value => arr.last) }
  end

  def self.startups_activated_per_week_for_chart(since = 10.weeks)
    date_start = Time.now - since
    a_by_w = {}
    current = Week.integer_for_time(Time.now)
    last = Week.integer_for_time(date_start)
    while current > last
      a_by_w[current] = 0
      current = Week.previous(current)
    end
    c_by_s = Hash.by_key(Checkin.order('created_at ASC').all, :startup_id, nil, true)
    c_by_s.each do |startup_id, checkins|
      # Skip unless their first checkin was after the date limit
      next unless checkins.first.time_window.first > date_start
      a_by_w[checkins.first.week] += 1
    end
    a_by_w.sort.map{|arr| OpenStruct.new(:key => arr.first, :value => arr.last) }
  end

  def self.startups_activated_per_day_for_chart(since = 2.weeks)
    uas = UserAction.where(:action => UserAction.id_for('checkins_first')).where(['created_at > ?', Time.now - since]).group(:user_id).order('created_at ASC')
    days = {}
    start = Date.today - since
    while start <= Date.today
      days[start.to_s] = 0
      start += 1.day
    end
    uas.each{|ua| days[ua.created_at.to_date.to_s] += 1 }
    days.map{|day, num| OpenStruct.new(:key => day, :value => num) }
  end

   # Creates data for chart that displays how many active connections there are per startup, per week
   # Active connection is someone who has checked in that week
   # Returns {:categories => [201223, 201224, 201225], :series => [{'0 Connections' => [35, 45, 56]}, {'1 Connection' => [23, 26, 15]}]}
   # hash with week as key, value is number of startups
  def self.connections_per_startup_for_chart(since = 10.weeks,  max_active = 10)
    # Populate categories
    tmp_data = Stats.generate_week_hash(Time.now - since)
    calc_data = tmp_data.dup

    # Load checkins into hash keyed by startup id, and then by week
    checkins_by_startup = Stats.checkins_by_startup_and_week(tmp_data.keys.first)

    Startup.all.each do |s|
      # First get relationship and checkin history for startup
      rh = Relationship.history_for_entity(s, 'Startup')['Startup']

      next if checkins_by_startup[s.id].blank?
        
      # For each week they were active (checked in), count how many of their connections were active (checked in)
      checkins_by_startup[s.id].each do |week, checkin|
        # Now check each startup they were connected to and see if they connected and checked in that week

        active_connections_this_week = 0

        # Checkin window is from start of after checkin for each week
        checkin_window = checkin.time_window
        start_after_checkin = checkin_window.last - 24.hours
        end_after_checkin = checkin_window.last

        unless rh.blank?
          rh.each do |startup_id, rel_window|
            # See if they were connected during the after checkin window and that the relationship didn't end before checkin window closed
            # Should it check to see if you're connected after to give comments?
            if rel_window.first < start_after_checkin && rel_window.last > end_after_checkin
              # Now see if this startup checked in this week
              active_connections_this_week += 1 if checkins_by_startup[startup_id].present? && checkins_by_startup[startup_id][week].present?
            end
          end
          active_connections_this_week = max_active if active_connections_this_week > max_active
        end

        calc_data[week][active_connections_this_week] ||= 0
        calc_data[week][active_connections_this_week] += 1
      end
    end

    categories = tmp_data.keys
    series = {}
    max_active.downto(0).each do |num_connections|
      series[num_connections.to_s] = []
      categories.each do |week|
        series[num_connections.to_s] << (calc_data[week][num_connections].present? ? calc_data[week][num_connections] : 0)
      end
    end
    {:categories => categories, :series => series }
  end


   # Find all startups who have done a checkin, and then track their continued activity til the present
  def self.weekly_retention_for_chart(since = 10.weeks)
    # find first startup and limit weeks to start there
    first_startup_joined_at = Startup.order('created_at ASC').first.created_at
    weeks = Stats.generate_week_hash(first_startup_joined_at)
    checkins_by_startup = Stats.checkins_by_startup_and_week(weeks.keys.first)
    startups = Hash.by_key(Startup.where(:id => checkins_by_startup.keys).all, :id)

    # Group startups by date created
    weeks.keys.each do |week|
      time_window = Week.window_for_integer(week, Checkin.default_offset)
      ids = []
      startups.values.each do |s|
        ids << s.id if time_window.first <= s.created_at && time_window.last >= s.created_at
      end

      # Now iterate through each week and see if these startups were active
      active_per_week = []
      weeks.keys.each do |week|
        num = 0
        ids.each do |startup_id|
          num += 1 if checkins_by_startup[startup_id].present? && checkins_by_startup[startup_id][week.to_i].present?
        end
        active_per_week << num
      end

      weeks[week] = active_per_week
    end
    { :categories => weeks.keys, :series => weeks }
  end

  def self.comments_per_checkin_for_chart(since = 10.weeks, max_comments = 10)
    weeks = Stats.generate_week_hash(Time.now - since).keys
    checkins = Checkin.where(['week >= ?', weeks.first]).all
    comments_per_checkin = Comment.where(:checkin_id => checkins.map{|c| c.id }).group(:checkin_id).count
    # Populate weeks hash with array for each # of comments
    data = {}
    blank_arr = []
    1.upto(weeks.size).each do |i|
      blank_arr << 0
    end
    max_comments.downto(0) do |num|
      data[num.to_s] = blank_arr.dup
    end

    # count number of comments each checkin got, grouped by week
    checkins.each do |c|
      if comments_per_checkin[c.id].present?
        num = comments_per_checkin[c.id] > max_comments ? max_comments : comments_per_checkin[c.id]
      else
        num = 0
      end
      data[num.to_s][weeks.index(c.week)] += 1
    end
    {:categories => weeks, :series => data}    
  end

  def self.checkins_by_startup_and_week(since_week = nil)
    # Load checkins into hash keyed by startup id, and then by week
    checkins_by_startup = {}
    checkins = since_week.present? ? Checkin.where(['week >= ?', since_week]).all : Checkin.all
    checkins.each do |c|
      checkins_by_startup[c.startup_id] ||= {}
      checkins_by_startup[c.startup_id][c.week] = c
    end
    checkins_by_startup
  end

  def self.generate_week_hash(since_date = nil)
    since_date ||= Time.now - 10.weeks
    tmp = []
    current = Week.integer_for_time(Time.now.end_of_week)
    last = Week.integer_for_time(since_date)
    while current > last
      tmp << current
      current = Week.previous(current)
    end
    # create hash
    weeks = {}
    tmp.reverse.each do |week|
      weeks[week] = {}
    end
    weeks
  end

    # Calculate week by week retention
    # From startups that checked in last week, what % checked in this week
    # If they did check in, segment by if they did after, before or before & after checkin)
  def self.weekly_retention_from_checkins
    checkins_by_week = Hash.by_key(Checkin.all, :week, nil, true)
    previous_week_ids = []
    weeks = []
    count = [:no_checkin, :before_checkin, :after_checkin, :before_after_checkin]
    data = {}
    count.each{|c| data[c] = [] }
    checkins_by_week.each do |week, checkins|
      this_count = {}
      count.each{|c| this_count[c] = 0 }
      checkins_by_startup = Hash.by_key(checkins, :startup_id)
      
      previous_week_ids.each do |id|
        c = checkins_by_startup[id]
        if c.present?
          if c.goal.present? && !c.completed?
            this_count[:before_checkin] += 1
          elsif c.goal.present? && c.completed?
            this_count[:before_after_checkin] += 1
          elsif c.goal.blank? && c.completed?
            this_count[:after_checkin] += 1
          end
        else
          this_count[:no_checkin] += 1
        end
      end
      # Total up and figure out %'s
      total = this_count.values.inject(0){|r, e| r + e }.to_f

      unless total == 0
        this_count.each do |label, num|
          data[label] << ((num.to_f / total) * 100).round(1)
        end
        weeks << week
      end

      previous_week_ids = []
      checkins.each do |c|
        # Save whether they checked in this week
        previous_week_ids << c.startup_id
      end
      
    end
    {:categories => weeks, :series => data}
  end

  def self.checkin_comments_correlation(above_num_comments = 0)
    # Calculate week by week
    # After receiving comments one week, how many startups checkin next week?
    # After not receiving any comments, does a startup checkin next week?
    checkins_by_week = Hash.by_key(Checkin.all, :week, nil, true)
    comments_by_checkin = Hash.by_key(Comment.where('checkin_id IS NOT NULL').all, :checkin_id, nil, true)
    user_ids_by_startup = {}
    User.all.each{|u| next if u.startup_id.blank?; user_ids_by_startup[u.startup_id] ||= []; user_ids_by_startup[u.startup_id] << u.id }
    data = [['Week', 'No Comments - No Checkin', 'Comments - No Checkin', 'No Comments - Checkin', 'Comments - Checked In', 'Total # Checkins']]
    got_comments_ids = []
    no_comments_ids = []
    checkins_by_week.each do |week, checkins|
      comments_checkin = comments_no_checkin = no_comments_checkin = no_comments_no_checkin = 0
      checked_in_ids = checkins.map{|c| c.startup_id }
      
      got_comments_ids.each do |startup_id|
        if checked_in_ids.include?(startup_id)
          comments_checkin += 1
        else
          comments_no_checkin += 1
        end
      end

      no_comments_ids.each do |startup_id|
        if checked_in_ids.include?(startup_id)
          no_comments_checkin += 1
        else
          no_comments_no_checkin += 1
        end
      end

      data << [week, no_comments_no_checkin, comments_no_checkin, no_comments_checkin, comments_checkin, checkins.size]

      got_comments_ids = []
      no_comments_ids = []
      all_ids = []

      checkins.each do |c|
        all_ids << c.startup_id
        # Save whether they did/didn't receive comments this week
        if comments_by_checkin[c.id].present?
          not_by_startup = []
          # Ignore comments made by the startup who made the checkin
          comments_by_checkin[c.id].each do |com|
            not_by_startup << com if user_ids_by_startup[c.startup_id].blank? || !user_ids_by_startup[c.startup_id].include?(com.user_id)
          end
          if not_by_startup.size > above_num_comments
            got_comments_ids << c.startup_id
          else
            no_comments_ids << c.startup_id
          end
        else
          no_comments_ids << c.startup_id
        end
      end
      
    end
    data
  end

  def self.relationships_data_for_startups(since = 4.weeks)
    data = [['Startup Id', 'Week', '# Active Connections', '# Connections', 'Total Received', 'Total Accepted']]
    rel_history = {}
    weeks = Stats.generate_week_hash(Time.now - since)
    startups_by_id = Hash.by_key(Startup.all, :id)
    users_by_startup = Hash.by_key(User.where('startup_id IS NOT NULL').all, :startup_id, nil, true)
    weeks.keys.each do |week|
      time_window = Week.window_for_integer(week, :after_checkin)
      checkins_by_startup = Hash.by_key(Checkin.where(:week => week).order(:startup_id).all, :startup_id)
      checkins_by_startup.each do |startup_id, checkin|
        startup = startups_by_id[startup_id]
        # Find out who they were connected with this week
        rel_history[startup.id] ||= Relationship.history_for_entity(startup, 'Startup')['Startup']

        connected_with_ids = []
        num_active_connections = 0
        unless rel_history[startup.id].blank?
          rel_history[startup.id].each do |s_id, history|
            connected_with_ids << s_id if history.first < time_window.first && history.last > time_window.first
          end

          # How many of their connections checked in?
          connected_with_ids.each{|id| num_active_connections += 1 if checkins_by_startup[id].present? }
        end

        # Find all relationships (that aren't suggested relationships)
        relationships = startup.initiated_relationships.not_suggested.where(["created_at > ? AND created_at < ?", time_window.first, time_window.last])

        total_initiated = total_received = total_accepted = total_same = 0

        relationships.each do |r|
          inv = r.inverse_relationship
          # they initiated it
          next unless inv.present?
          if r.created_at < inv.created_at
            total_initiated += 1
          # the other startup initiated it
          elsif r.created_at > inv.created_at
            total_accepted += 1 if r.approved?
            total_received += 1
          end
        end
        data << [startup.id, week, num_active_connections, connected_with_ids.size, total_received, total_accepted]
      end
    end
    data
  end

  def self.detailed_relationships_data_for_startups(since = 4.weeks)
    data = [['Startup Id', 'Week', '# Active Connections', '# Connections', '# Comments Received', 'Total Initiated', 'Total Received', 'Pending', 'Accepted', 'Rejected/Removed', 'Rejected/Removed By Other']]
    rel_history = {}
    weeks = Stats.generate_week_hash(Time.now - since)
    startups_by_id = Hash.by_key(Startup.all, :id)
    users_by_startup = Hash.by_key(User.where('startup_id IS NOT NULL').all, :startup_id, nil, true)
    weeks.keys.each do |week|
      time_window = Week.window_for_integer(week, :after_checkin)
      checkins_by_startup = Hash.by_key(Checkin.where(:week => week).order(:startup_id).all, :startup_id)
      checkins_by_startup.each do |startup_id, checkin|
        startup = startups_by_id[startup_id]
        # Find out who they were connected with this week
        rel_history[startup.id] ||= Relationship.history_for_entity(startup, 'Startup')['Startup']

        connected_with_ids = []
        num_active_connections = 0
        unless rel_history[startup.id].blank?
          rel_history[startup.id].each do |s_id, history|
            connected_with_ids << s_id if history.first < time_window.first && history.last > time_window.first
          end

          # How many of their connections checked in?
          connected_with_ids.each{|id| num_active_connections += 1 if checkins_by_startup[id].present? }
        end

        # Number of comments they received on this checkin not by their team
        team_member_ids = users_by_startup[startup.id].blank? ? [] : users_by_startup[startup.id].map{|u| u.id }
        if team_member_ids.blank? # users have been deleted
          num_comments_received = Comment.where(:checkin_id => checkin.id).count
        else 
          num_comments_received = Comment.where(:checkin_id => checkin.id).where("user_id NOT IN (#{team_member_ids.join(',')})").count
        end

        # Find all relationships (that aren't suggested relationships)
        relationships = startup.initiated_relationships.not_suggested.where(["created_at > ? AND created_at < ?", time_window.first, time_window.last])

        total_initiated = total_received = num_rejected = num_rejected_by_other = num_pending = num_accepted = 0

        relationships.each do |r|
          inv = r.inverse_relationship
          # they initiated it
          next unless inv.present?
          if r.created_at < inv.created_at
            total_initiated += 1
            num_rejected += 1 if r.rejected?
          # the other startup initiated it
          elsif r.created_at > inv.created_at
            total_received += 1
            num_rejected_by_other if r.rejected?
          end
          num_pending += 1 if r.pending?
          num_accepted += 1 if r.approved?
        end
        data << [startup.id, week, num_active_connections, connected_with_ids.size, num_comments_received, total_initiated, total_received, num_pending, num_accepted, num_rejected, num_rejected_by_other]
      end
    end
    data
  end

    # Grouped by session, and only counts first checkins
  def self.activation_funnel_for_startups(since = 14.days)
    days = []
    blank_arr = []
    current = Time.now - since
    while current < Time.now
      days << current.to_date
      blank_arr << 0 #Random.rand(150)
      current += 1.day
    end

    action_labels = ['registrations_new', 'registrations_create', 'checkins_first']
    action_ids = action_labels.map{|l| UserAction.id_for(l) }

    tmp_data = {}
    tmp_data2 = {}
    days.each do |day|
      tmp_data[day] = {}
      action_ids.each do |aid|
        tmp_data[day][aid] = 0
      end
    end
    action_ids.each{|aid| tmp_data2[aid] = blank_arr.dup }

    # Dedupe is using session id as the unique identifier
    ua_by_session_id = Hash.by_key(UserAction.where(:action => action_ids).where(['created_at > ?', Time.now - since]).order('created_at ASC').includes(:user), :session_id, nil, true)

    ua_by_session_id.each do |session_id, uas|
      next if session_id.blank?

      date = uas.first.created_at.to_date
      
      # look for furthest along action (lowest index)
      furthest_along = 99
      ua = nil
      #checkin_action = action_ids[action_labels.index('checkins_create')]
      uas.each do |a|
        index = action_ids.index(a.action)
        if index < furthest_along
          # if a.action == checkin_action # If a checkin, only count action if this was their 1st completed checkin (give it a 5 min grace period)
          #   next if Checkin.where(:startup_id => a.user.startup_id).where(['created_at < ?', a.created_at - 5.minutes]).completed.count > 0
          # end
          furthest_along = index
          ua = a
        end
      end
      tmp_data[date][ua.action] += 1 if ua.present?
    end

    # Now figure out correct distribution in percent between all actions
    tmp_data.each do |date, action_hash|
      total = action_hash.values.inject(0){|r, e| r + e }.to_f
      unless total == 0
        action_hash.each do |action_id, num|
          tmp_data2[action_id][days.index(date)] = num.blank? ? 0 : ((num.to_f / total) * 100).round
        end
      end
    end


    # Now assemble correct data structure and convert absolute values to percent
    data = {}
    tmp_data2.each do |action_id, action_arr|
      data[action_labels[action_ids.index(action_id)]] = action_arr
    end

    # Hash of action => [day, day, day]
    {:categories => days, :series => data }
  end
end