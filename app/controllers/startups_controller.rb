class StartupsController < ApplicationController
  before_filter :login_required

  def new
    redirect_if_user_has_startup
    @startup = Startup.new
  end

  def create
    redirect_if_user_has_startup
    @startup = Startup.new(params[:startup])
    if @startup.save
      current_user.update_attribute('startup', @startup)
      flash[:notice] = "Startup information has been saved. Thanks!"
      redirect_to "/startup"
    else
      render :new
    end
  end

  def discover
    @startups = Startup.public.order(:name).includes(:meeting)
  end

  def show
    @startup = Startup.find(params[:id]) unless params[:id].blank?
    @startup ||= current_user.startup if @startup.blank? and user_signed_in?
    redirect_unless_user_can_view_startup(@startup)
  end

  before_filter :startup_required, :only => [:show, :edit, :update, :onboard, :onboard_next]

  def dashboard
    @step = @startup.onboarding_step
    render :action => :onboard
  end

  def edit
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

    # multi-page process that any new startup has to go through
  def onboard
    @step = @startup.onboarding_step
    @complete = @startup.onboarding_complete?
    @startups_with_videos = Startup.with_intro_video.order(updated_at: -1).paginate(:page => params[:page] || 1, :per_page => 10)
    # hack - this needs to be for this week, but we're changing dashboard soon
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
    elsif params[:startup] and params[:startup][:youtube_intro_url]
      if !params[:startup][:youtube_intro_url].blank? and @startup.update_attribute('intro_video_url', params[:startup][:intro_video_url])
        @startup.onboarding_step_increment!
      else
        flash[:alert] = "Looks like you forgot to paste in your Youtube URL"
      end
    else
      @startup.onboarding_step_increment!
    end
    redirect_to :action => :onboard
  end

  protected

  def redirect_unless_user_can_view_startup(startup)
    if user_signed_in?
      return true if current_user.admin? or current_user.startup_id == startup.id
    elsif startup.public?
      return true
    end
    flash[:alert] = "Sorry but you don't have permissions to view that startup"
    redirect_to discover_startup_path
    return false
  end

  def redirect_if_user_has_startup
    # Make sure they don't create another startup
    if !current_user.startup.blank?
      flash.keep
      redirect_to "/startup"
      return
    end
  end
end