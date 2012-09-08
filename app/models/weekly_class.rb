class WeeklyClass < ActiveRecord::Base
  attr_accessible :week, :user_ids

  serialize :user_ids
  serialize :clusters

  before_save :calculate_cached_fields

  def self.populate_for_past_weeks
    return unless WeeklyClass.count == 0
    classes = []
    num_users_left = User.count
    curr_week = Week.integer_for_time(Time.now.beginning_of_week)
    while(num_users_left > 0) do
      w = WeeklyClass.new(:week => curr_week)
      users = User.where(['created_at >= ? AND created_at <= ?', w.time_window.first, w.time_window.last]).all
      num_users_left -= users.size
      w.users = users
      classes << w
      curr_week = Week.previous(curr_week) # calculate previous week
    end
    # Save in reverse order to get id right
    classes.reverse.each{|wc| wc.save }
    classes
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

  def time_window
    WeeklyClass.time_window_for_week(self.week)
  end

  def users
    return @users if @users.present?
    @users = User.find(self.user_ids)
  end

  def users=(users)
    self.user_ids ||= []
    self.user_ids += users.map{|u| u.id }
    self.user_ids.uniq!
  end

  # Distance calculation and clustering
  def create_clusters(max_radius = 100.0)
    # Load all users
    users = self.users
    # Ensure all users are geocoded
    User.transaction do
      users.each{|u| u.geocode_from_ip unless u.geocoded? }
    end

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
    clusters
  end
  
  protected

  def calculate_cached_fields
    if self.user_ids.present? && self.user_ids_changed?
      self.num_users = self.user_ids.size
      self.num_startups = self.users.map{|u| u.startup_id }.uniq.size
      self.num_countries = 0
      self.num_industries = ActsAsTaggableOn::Tagging.where(:taggable_type => 'User', :taggable_id => self.user_ids).group(:tag_id).count.keys.size
      self.location_clusters = self.create_clusters
    end
  end
end
