class RatingsController < ApplicationController
  #around_filter :record_user_action, :only => [:create]
  before_filter :login_required
  load_and_authorize_resource
  
  def index
    if current_user.entrepreneur?
      @startup = current_user.startup
      if current_user.startup.can_access_mentors_and_investors?
        @ratings = @startup.ratings.ordered
        unless @ratings.blank?
          @weakest_element_data = Rating.chart_data_from_ratings(@ratings, :weakest_element)
          @contact_in_data = Rating.chart_data_from_ratings(@ratings, :contact_in)
        end
      else
        @startup_elements = @startup.investor_mentor_elements(true)
      end
      render :action => :entrepreneur
    else
      authorize! :see_ratings_page, current_user
      # startups = Hash.by_key(current_user.connected_to, :id)
      startups = Startup.limit(50).all
      @checkins_by_week = Checkin.for_startups_by_week(startups, 20)
      @startups_by_id =  Hash.by_key(startups, :id)
      @total_num_ratings = current_user.ratings.count
      @total_value_adds = current_user.ratings_awesomes.count
      # Will grab four weeks of checkins for these startups
      calculate_suggested_startup_completeness
      render :action => :mentor_investor
    end
  end

  def new
    authorize! :investor_mentor_connect_with_startups, current_user
    @startup = current_user.suggested_startups(1).first

    if @startup.blank?
      flash[:notice] = "Thanks, you've reviewed all of the startups currently available to you."
      redirect_to :action => :index
      return
    end

    calculate_suggested_startup_completeness

    @checkin_history = Checkin.history_for_startup(@startup)
    @screenshots = @startup.screenshots.ordered

    @rating.startup = @startup
    @rating.interested = false

    @instrument = @startup.instruments.first
    @measurements = @instrument.measurements.ordered_asc.all unless @instrument.blank?

    @checkins = @startup.checkins.ordered
  end

  def create
    @rating.user = current_user
    if @rating.save
      #flash[:notice] = "Your rating has been stored!"
      # They are done rating startups
      if params[:commit].match(/stop/i) != nil
        @redirect_to = ratings_path
      else # They want to continue
        # Check if they are above their limit
        if current_user.can_connect_with_startups?
          @redirect_to = new_rating_path
        else
          flash[:alert] = "You've already contacted a startup this week, please come back later or upgrade your account to connect with more startups."
          @redirect_to = ratings_path
        end
      end
      # JS will render page that redirects to url
      respond_to do |format|
        format.js { render 'layouts/redirect_to' }
        format.html { redirect_to @redirect_to }
      end
    else
      respond_to do |format|
        format.js { render :action => :edit }
        format.html { render :nothing => true }
      end
    end
  end

  protected

  def calculate_suggested_startup_completeness
    @total_suggested_startups = User::INVESTOR_MENTOR_STARTUPS_PER_WEEK
    @num_startups_left = current_user.suggested_relationships('Startup').count
    return if @num_startups_left == 0
    @pct_complete = ((@num_startups_left.to_f / @total_suggested_startups.to_f) * 100).to_i
  end
end
