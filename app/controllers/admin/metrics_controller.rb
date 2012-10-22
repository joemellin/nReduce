class Admin::MetricsController < ApplicationController
  before_filter :admin_required

  def index
    @checkin_data = Stats.checkins_per_week_for_chart(1.year)
    @comment_data = Stats.comments_per_week_for_chart(1.year)
    @active_teams_data = Stats.connections_per_startup_for_chart(10.weeks)
    @activation_data = Stats.startups_activated_per_week_for_chart(1.year)
  end
end