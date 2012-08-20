class InvestorsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required

  def index
    authorize! :see_investor_page, current_user
    @profile_completeness_percent = (current_user.startup.investor_profile_completeness_percent * 100).round unless current_user.startup.blank?
  end

  # Show a new startup to an investor
  def show_startup
    authorize! :investor_connect_with_startups, current_user
    # Only allow temporary investor account access to their suggested startups
    if [2367, 2375].include?(current_user.id)
      @startup = current_user.suggested_startups(1).first
    else
      @startup = Startup.find 319
      Relationship.suggest_connection(current_user, @startup, :startup_investor)
    end
    @checkin_history = Checkin.history_for_startup(@startup)
    @screenshots = @startup.screenshots.ordered

    @rating = Rating.new
    @rating.startup = @startup
  end
end
