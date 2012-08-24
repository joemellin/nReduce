class InvestorsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required

  def index
    authorize! :see_investor_page, current_user
    @profile_completeness_percent = (@startup.investor_profile_completeness_percent * 100).round unless @startup.blank?
    calculate_suggested_startup_completeness if current_user.roles? :approved_investor
  end

  # Show a new startup to an investor
  def show_startup
    authorize! :investor_connect_with_startups, current_user
    # Only allow temporary investor account access to their suggested startups
    if [2367, 2375, 2435, 2436, 2437, 2438].include?(current_user.id)
      calculate_suggested_startup_completeness
      @startup = current_user.suggested_startups(1).first
    else
      @startup = Startup.find 319
      Relationship.suggest_connection(current_user, @startup, :startup_investor)
    end
    @checkin_history = Checkin.history_for_startup(@startup)
    @screenshots = @startup.screenshots.ordered

    @rating = Rating.new
    @rating.startup = @startup
    @rating.interested = false

    @instrument = @startup.instruments.first
  end

  protected

  def calculate_suggested_startup_completeness
    @total_suggested_startups = 30
    @num_startups_left = @total_suggested_startups - current_user.suggested_startups(1000).count
    @pct_complete = ((@num_startups_left.to_f / @total_suggested_startups.to_f) * 100).to_i
  end
end
