class WeeklyClass < ActiveRecord::Base
  has_many :users
  has_many :startups, :through => :users
  has_many :invites

  attr_accessible :week

  serialize :clusters

  before_save :calculate_cached_fields

  def self.populate_for_past_weeks
    return unless WeeklyClass.count == 0
    weekly_classes = []
    all_users = []
    num_users_left = User.count
    curr_week = Week.integer_for_time(Time.now.beginning_of_week)
    while(num_users_left > 0) do
      wc = WeeklyClass.new(:week => curr_week)
      wc.save
      users = User.where(['created_at >= ? AND created_at <= ?', wc.time_window.first, wc.time_window.last]).all
      num_users_left -= users.size
      wc.users = users
      weekly_classes << wc
      curr_week = Week.previous(curr_week) # calculate previous week
    end
    weekly_classes.each do |wc| 
      # Add weekly class id to all users
      #User.transaction do
      #  wc.users.each{|u| u.save(:validate => false) }
      #end
      # Update cached stats
      wc.save
    end
    weekly_classes
  end

  def self.current_class
    WeeklyClass.find_or_create_by_week(:week => WeeklyClass.current_week)
  end

  def self.current_week
    Week.integer_for_time(Time.now, :join_class)
  end

  def self.time_window_for_week(week)
    Week.window_for_integer(week, :join_class)
  end

  def self.class_for_user(user)
    week = Week.integer_for_time(user.created_at, :join_class)
    WeeklyClass.find_or_create_by_week(:week => week)
  end

  def self.top_stats(ignore_weekly_class = nil)
    wc = WeeklyClass.select('MAX(weekly_classes.num_users) AS max_users, MAX(weekly_classes.num_startups) AS max_startups, MAX(weekly_classes.num_countries) AS max_countries, MAX(weekly_classes.num_industries) as max_industries')
    wc = wc.where(['id != ?', ignore_weekly_class.id]) if ignore_weekly_class.present?
    wc.all.first
  end

  # Finds current week, and then emails people from previous week who didn't join to join this week
  def self.email_incomplete_startups_from_previous_week
    current_week = WeeklyClass.current_class
    previous_week = current_week.previous_class
    incomplete_startups = previous_week.incomplete_startups
    incomplete_startups.each do |s|
      Notification.create_for_join_next_week(s, current_week)
    end
    incomplete_startups
  end

  def previous_class
    WeeklyClass.where(['week < ?', self.week]).order('week DESC').first
  end

  def activate_all_completed_startups
    activated = []
    self.startups.each do |s|
      if s.can_enter_nreduce?
        s.force_setup_complete!
        activated << s
      end
    end
    activated
  end

  # all startups who haven't completed their profile
  def incomplete_startups
    incomplete = []
    self.startups.each do |s|
      incomplete << s unless s.can_enter_nreduce?
    end
    incomplete
  end

  # This is the time window in which you join
  def in_join_window?
    starts = self.time_window.last + 1.second
    duration = Week.time_window_offsets[:join_class].last
    ends = starts + duration
    Time.now >= starts && Time.now <= ends
  end

  def description
    tw = self.time_window
    "#{tw.first.strftime('%b %-d')} - #{tw.last.strftime('%b %-d')}"
  end

  def time_window
    WeeklyClass.time_window_for_week(self.week)
  end

  def join_time
    self.time_window.last
  end

  # Distance calculation and clustering
  def self.create_clusters(users, max_radius = 250.0)
    return nil if users.blank?
    # need to dupe or else array gets modified
    users = users.dup 
    # Ensure all users are geocoded
    users.each{|u| u.geocode_from_ip unless u.geocoded? }

    clusters = []
    while users.size > 0
      # Choose a random point
      center = users.sample
      
      # Sort by distance from starting point
      users.sort_by_distance_from(center)
    
      c = Cluster.new
      c.user_ids = []
      added_users = []
      
      # set this as center for now
      c.lat, c.lng, c.location = center.lat, center.lng, center.location

      # this will add the user set as center
      users.each do |u|
        if u.distance_from(center, :units => :miles) < max_radius
          c.user_ids.push(u.id)
          added_users.push(u)
        end
      end
      # Ideally we should find the true center and reassign the lat/lng based on that
      # c.recenter
      added_users.each{|e| users.delete(e) }
      clusters.push(c)
    end
    # Sort by clusters that are biggest first
    clusters.sort{|a,b| a.user_ids.size <=> b.user_ids.size }.reverse
  end

  def create_clusters
    self.clusters = WeeklyClass.create_clusters(self.users)
  end

  protected

  def calculate_cached_fields
    us = self.users
    if us.present? && us.size != self.num_users
      self.num_users = us.size
      self.num_startups = us.map{|u| u.startup_id }.uniq.size
      self.num_countries = us.map{|u| u.country }.uniq.size
      self.num_industries = ActsAsTaggableOn::Tagging.where(:taggable_type => 'User', :taggable_id => us.map{|u| u.id }).group(:tag_id).count.keys.size
      self.clusters = WeeklyClass.create_clusters(us)
    else
      self.clusters = []
    end
    true
  end
end
