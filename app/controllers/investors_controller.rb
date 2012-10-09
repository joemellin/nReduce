class InvestorsController < ApplicationController
  around_filter :record_user_action, :only => [:show_startup]
  before_filter :login_required

  def index
    authorize! :see_investor_page, current_user
    if current_user.entrepreneur? && current_user.startup_id.present?
      @startup = current_user.startup
      @startup_elements = @startup.mentor_and_investor_elements
      if @startup_elements[:total][:passed] && (@startup.mentorable? || @startup.investable?) # if they have all elements passed show feedback
        redirect_to startup_ratings_path(@startup)
        return
      end
    end
    @profile_completeness_percent = (@startup.investor_profile_completeness_percent * 100).round unless @startup.blank?
    calculate_suggested_startup_completeness if current_user.roles? :approved_investor
  end

  # Show a new startup to an investor
  def show_startup
    authorize! :investor_connect_with_startups, current_user
    # Only allow temporary investor account access to their suggested startups
    if [2367, 2375, 2435, 2436, 2437, 2438, 2459, 2466].include?(current_user.id)
      calculate_suggested_startup_completeness
      @startup = current_user.suggested_startups(1).first
    else
      @startup = Startup.find 319
      Relationship.suggest_connection(current_user, @startup, :startup_investor)
    end
    
    if @startup.blank?
      flash[:notice] = "Thanks, you've reviewed all of the startups currently available to you."
      redirect_to :action => :index
      return
    end

    @checkin_history = Checkin.history_for_startup(@startup)
    @screenshots = @startup.screenshots.ordered

    @rating = Rating.new
    @rating.startup = @startup
    @rating.interested = false

    @instrument = @startup.instruments.first
    @measurements = @instrument.measurements.ordered_asc.all unless @instrument.blank?

    @checkins = @startup.checkins.ordered
  end

  protected

  def calculate_suggested_startup_completeness
    @total_suggested_startups = current_user.suggested_relationships('Startup').count
    @num_startups_left = @total_suggested_startups - current_user.suggested_startups(1000).count
    @pct_complete = ((@num_startups_left.to_f / @total_suggested_startups.to_f) * 100).to_i
  end
end
