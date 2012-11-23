class OnboardController < ApplicationController
  before_filter :login_required
  before_filter :load_requested_or_users_startup

  def show
    @onboard = true
    @onboarding_step = params[:id].to_i
    render "step_#{params[:id]}"
  end

    # Begin a new onboarding process for a user
  def start
    # if no type passed, get from user
    # params[:type] =  if params[:type].blank?
    # if params[:type].blank? # if still no onboarding type
    #   redirect_to current_user
    # else
    #   redirect_to_onboarding_start(params[:type])
    # end
    redirect_to_onboarding_start(:startup)
  end

  def current_step
    @onboard = true
    @last_step = current_onboarding_step == Onboarding.num_onboarding_steps
    @hide_footer = true
    #@user = current_user
    # Check if user has completed
    if current_onboarding_step > Onboarding.num_onboarding_steps
      # completed onboarding
      #@user.onboarding_completed!(current_onboarding_type)
      current_user.welcome_seen!
      redirect_to '/'
    else
      @onboarding_step = current_onboarding_step
      render "step_#{current_onboarding_step}"
    end
  end

    # User just completed a step
    # Collect and update data, and redirect to next step if they have succesfully completed step
  def next
    # Check if we have any form data - Startup form or  Youtube url or
    # @user = current_user
    # if !params[:user_form].blank? and !params[:user].blank?
    #   if @user.update_attributes(params[:user])
    #     onboarding_step_increment!
    #   else
    #     flash.now[:alert] = "Hm, we had some problems updating your account."
    #     render "step_#{current_onboarding_step}" && return
    #   end
    # elsif params[:user]
    #   if !params[:user][:intro_video_url].blank? and @user.update_attributes(params[:user])
    #     onboarding_step_increment!
    #   else
    #     flash[:alert] = "Looks like you forgot to paste in your Youtube URL"
    #     render "step_#{current_onboarding_step}" && return
    #   end
    # elsif params[:startup]
    #   if @startup.update_attributes(params[:startup])
    #     onboarding_step_increment!
    #   else
    #     flash.now[:alert] = "Hm, we had some problems updating your account."
    #     render "step_#{current_onboarding_step}" && return
    #   end
    # else
    #   onboarding_step_increment!
    # end
    onboarding_step_increment!
    redirect_to :action => :current_step
  end

  def go_to
    self.current_onboarding_step = params[:step].to_i
    redirect_to :action => :current_step
  end

  protected

  # Validate current onboarding process type, save in session, and redirect to start it
  def redirect_to_onboarding_start(type = nil)
    session[:onboarding_step] = 1
    redirect_to :action => :current_step
  end

  def current_onboarding_step=(step)
    session[:onboarding_step] = step
  end

  def current_onboarding_step
    return session[:onboarding_step] if session[:onboarding_step].present?
    self.current_onboarding_step = 1
  end

  # User has completed a step, increment to next step for this onboarding type
  def onboarding_step_increment!
    session[:onboarding_step] += 1
    # See if we need to skip the next onboarding step
    # while(Onboarding.skip_onboarding_step?(session[:onboarding_step]))
    #   session[:onboarding_step] += 1
    # end
    session[:onboarding_step]
  end
end
