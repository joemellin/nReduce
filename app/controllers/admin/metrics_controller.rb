class Admin::MetricsController < ApplicationController
  before_filter :admin_required
  caches_action :index, :expires_in => 10.minutes

  def index
    #@checkin_data = Stats.checkins_per_week_for_chart(2.months)
    #@comment_data = Stats.comments_per_week_for_chart(2.months)
    @comments_per_checkin_data = Stats.comments_per_checkin_for_chart(2.months)
    @active_teams_data = Stats.connections_per_startup_for_chart(2.months)
    @retention_data = Stats.weekly_retention_for_chart(1.year) # do this one for all time
    @retention_by_checkins_data = Stats.weekly_retention_from_checkins # do this one for all time
    @activation_funnel_data = Stats.activation_funnel_for_startups(14.days)
    @activation_data = Stats.startups_activated_per_day_for_chart(14.days)
  end
end