class OnboardController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required

    # Begin a new onboarding process for a user
  def start
    start_onboarding_process(params[:type])
    redirect_to :action => :current_step
  end

  def current_step
    if @user.onboarding_complete?
      redirect_to '/'
    else
      @step = @user.onboarding_step
      render "users/onboard/step_#{@step}"
    end
  end

    # did this as a separate POST / redirect action so that 
    # if you refresh the onboard page it doesn't go to the next step
  def onboard_next
    # Check if we have any form data - Startup form or  Youtube url or 
    if !params[:user_form].blank? and !params[:user].blank?
      if @user.update_attributes(params[:user])
        @user.onboarding_step_increment! 
      else
        flash.now[:alert] = "Hm, we had some problems updating your account."
        @step = @user.onboarding_step
        render "users/onboard/step_#{@step}"
        return
      end
    elsif params[:user]
      if !params[:user][:intro_video_url].blank? and @user.update_attributes(params[:user])
        @user.onboarding_step_increment!
      else
        flash[:alert] = "Looks like you forgot to paste in your Youtube URL"
        @step = @user.onboarding_step
        render "users/onboard/step_#{@step}"
        return
      end
    else
      @user.onboarding_step_increment!
    end
    redirect_to :action => :onboard
  end

  protected

  def start_onboarding_process(type = nil)
    if type.blank? or 
    session[:onboarding_type] = type
    session[:onboarding_step] = 1
  end

  def current_onboarding_step
    session[:onboarding_step]
  end
end
