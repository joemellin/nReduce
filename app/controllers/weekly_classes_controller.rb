class WeeklyClassesController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource

  def show
    @waiting_for_next_class = true
    @stats = WeeklyClass.top_stats
    @invite = Invite.new(:weekly_class => @weekly_class, :from_id => current_user.id, :invite_type => Invite::TEAM_MEMBER)
    @sent_invites = current_user.sent_invites.ordered
    @startup = current_user.startup
  end
end
