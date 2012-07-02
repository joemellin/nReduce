class StartupsController < ApplicationController
  around_filter :record_user_action, :except => [:onboard_next, :stats]
  before_filter :login_required

  def index
    redirect_to :action => :search
  end

  def new
    @startup = Startup.new(:website_url => 'http://')
  end

  def create
    @startup = Startup.new(params[:startup])
    if @startup.save
      current_user.update_attribute('startup_id', @startup.id)
      flash[:notice] = "Startup information has been saved. Thanks!"
      redirect_to "/startup"
    else
      render :new
    end
  end

  before_filter :load_requested_or_users_startup, :except => [:index, :stats]
  load_and_authorize_resource :except => [:index, :stats]

  def show
    @owner = true if user_signed_in? and (@startup.id == current_user.startup_id)
    @can_view_checkin_details = can? :read, Checkin.new(:startup => @startup)
    @num_checkins = @startup.checkins.count
    @num_awesomes = @startup.awesomes.count
    @checkins = @startup.checkins.ordered
    @relationship = Relationship.between(current_user.startup, @startup) unless current_user.startup.blank?
    if current_user.mentor?
      @entity = current_user
    elsif !@startup.blank?
      @entity = @startup
    end
  end

  def search
    if !params[:search].blank?
      # sanitize search params
      params[:search].select{|k,v| [:name, :meeting_id, :industry_id].include?(k) }

      # save in session for pagination
      @search = session[:search] = params[:search]
    elsif !params[:page].blank? 
      @search = session[:search]
    end

    @search ||= {}
    @search[:page] = params[:page] || 1

    # Establish basic query to find public startups
    @startups = Startup.is_public.where(:onboarding_step => Startup.num_onboarding_steps).order('startups.name').includes(:team_members).paginate(:page => @search[:page], :per_page => 10)

    # Add conditions
    # Ignore current user's startup
    #if user_signed_in? and !current_user.startup_id.blank?
    #  @startups = @startups.where("startups.id != '#{current_user.startup_id}'")
    #end
    unless @search[:name].blank?
      @startups = @startups.where(['startups.name LIKE ?', "%#{@search[:name]}%"])
    end
    unless @search[:meeting_id].blank?
      @startups = @startups.where(['startups.meeting_id = ?', @search[:meeting_id]])
    end
    unless @search[:industry_id].blank?
      @startups = @startups.where(['startups.industry_id = ?', @search[:industry_id]])
    end
    @ua = {:data => @search}
    @meetings_by_id = Meeting.location_name_by_id
    @tags_by_startup_id = Startup.tags_by_startup_id(@startups)

    if current_user.mentor?
      @entity = current_user
    elsif !@startup.blank?
      @entity = @startup
    end
  end

  #
  # Actions for user's startup
  #

  def dashboard
    @step = @startup.onboarding_step
    render :action => :onboard
  end

  def edit
    @profile_elements = @startup.profile_elements
    @profile_completeness_percent = (@startup.profile_completeness_percent * 100).round
  end

  def update
    @startup.attributes = params[:startup]
    if @startup.save
      flash[:notice] = "Startup information has been saved. Thanks!"
      redirect_to '/startup'
    else
      render :edit
    end
  end

    # Removes a team member
  def remove_team_member
    u = User.find(params[:user_id])
    if @startup.id != u.startup_id
      flash[:alert] = "#{u.name} could not be removed because they aren't a member of your team."
    else
      u.startup_id = nil
      if u.save
        flash[:notice] = "#{u.name} has been removed from your team."
      else
        flash[:alert] = "Sorry, but #{u.name} could not be removed at this time."
      end
    end
    redirect_to edit_startup_path(@startup)
  end

    # multi-page process that any new startup has to go through
  def onboard
    @step = @startup.onboarding_step
    @complete = @startup.onboarding_complete?
    @checkin_total = Checkin.count if @startup.onboarding_complete?
  end

    # did this as a separate POST / redirect action so that 
    # if you refresh the onboard page it doesn't go to the next step
  def onboard_next
    # Check if we have any form data - Startup form or  Youtube url or 
    if params[:startup_form] and !params[:startup].blank?
      if @startup.update_attributes(params[:startup])
        @startup.onboarding_step_increment! 
      else
        flash.now[:alert] = "Hm, we had some problems updating your startup."
        @step = @startup.onboarding_step
        render :action => :onboard
        return
      end
    elsif params[:startup] and params[:startup][:intro_video_url]
      if !params[:startup][:intro_video_url].blank? and @startup.update_attribute('intro_video_url', params[:startup][:intro_video_url])
        @startup.onboarding_step_increment!
      else
        flash[:alert] = "Looks like you forgot to paste in your Youtube URL"
      end
    else
      @startup.onboarding_step_increment!
    end
    redirect_to :action => :onboard
  end

  #
  # ADMIN ONLY
  #

  before_filter :admin_required, :only => [:stats]

  def stats
    respond_to do |format|
      format.csv { send_data(Startup.generate_stats_csv,
                   :type => 'text/csv; charset=iso-8859-1; header=present',
                   :disposition => "attachment; filename=startup_stats_#{Date.today.to_s(:db)}.csv")
                 }
      format.html { render :nothing => true }
    end
  end
end