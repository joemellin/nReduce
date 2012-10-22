class Admin::MetricsController < ApplicationController
  before_filter :admin_required

  def index
    @checkin_data = Stats.checkins_per_week_for_chart(2.months)
    @comment_data = Stats.comments_per_week_for_chart(2.months)
    @active_teams_data = Stats.connections_per_startup_for_chart(2.months)
    @activation_data = Stats.startups_activated_per_week_for_chart(2.months)
  end
end