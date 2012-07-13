class OnboardController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup

    # Begin a new onboarding process for a user
  def start
    # if no type passed, get from user
    params[:type] = current_user.onboarding_type if params[:type].blank?
    redirect_to_onboarding_start(params[:type])
  end

  def current_step
    # Check if user has completed
    if current_onboarding_step == Onboarding.num_onboarding_steps
      redirect_to '/'
    else
      render "onboarding/step_#{current_onboarding_step}"
    end
  end

    # User just completed a step
    # Collect and update data, and redirect to next step if they have succesfully completed step
  def next
    # Check if we have any form data - Startup form or  Youtube url or 
    if !params[:user_form].blank? and !params[:user].blank?
      if @user.update_attributes(params[:user])
        onboarding_step_increment!
      else
        flash.now[:alert] = "Hm, we had some problems updating your account."
        render "users/step_#{current_onboarding_step}"
        return
      end
    elsif params[:user]
      if !params[:user][:intro_video_url].blank? and @user.update_attributes(params[:user])
        onboarding_step_increment!
      else
        flash[:alert] = "Looks like you forgot to paste in your Youtube URL"
        render "users/step_#{current_onboarding_step}" && return
      end
    elsif params[:startup]
      if @startup.update_attributes(params[:startup])
        onboarding_step_increment!
      else
        flash.now[:alert] = "Hm, we had some problems updating your account."
        render "users/step_#{current_onboarding_step}" && return
      end
    else
      onboarding_step_increment!
    end
    redirect_to :action => :current_step
  end

  protected

  # Validate current onboarding process type, save in session, and redirect to start it
  def redirect_to_onboarding_start(type = nil)
    if !type.blank? and Onboardable.onboarding_types.include?(type.to_sym)
      session[:onboarding_type] = type.to_sym
      session[:onboarding_step] = 1
      redirect_to :action => :current_step
    else
      flash[:alert] = "#{type} is not a valid onboarding flow."
      redirect_to current_user
    end
  end

  def current_onboarding_step
    session[:onboarding_step]
  end

  def current_onboarding_type
    session[:onboarding_type]
  end

  # User has completed a step, increment to next step for this onboarding type
  def onboarding_step_increment!
    session[:onboarding_step] += 1
    # See if we need to skip the next onboarding step
    while(Onboarding.skip_onboarding_step?(session[:onboarding_type], session[:onboarding_step]))
      session[:onboarding_step] += 1
    end
    session[:onboarding_step]
  end
end
