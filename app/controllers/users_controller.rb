class UsersController < ApplicationController
  around_filter :record_user_action, :except => [:reset_hipchat_account]
  before_filter :login_required
  before_filter :load_user_if_me_or_current
  load_and_authorize_resource

  def index
    redirect_to '/'
  end

  def complete_account
  end

  def show
    # Load current invite if they have one  - don't search by email because that opens security hole where a user can sign up with an email they don't own and get invite - really should be verifying email
    if @user.id == current_user.id
      @current_invite = Invite.not_accepted.where(:to_id => current_user.id).first
      @current_invite = nil if @current_invite and !@current_invite.active?
    end
  end

  def edit
    @profile_elements = @user.profile_elements
    @profile_completeness_percent = (@user.profile_completeness_percent * 100).round
  end

  def update
    if @user.update_attributes(params[:user])
      flash[:notice] = "Your account has been updated!"
      redirect_to :action => :show
    else
      if params[:complete_account].to_s == 'true'
        render :action => :complete_account
      else
        render :action => :edit
      end
    end
  end
  
  def chat
    @user.generate_hipchat! unless @user.hipchat?
  end

  def reset_hipchat_account
    if @user.reset_hipchat_account!
      flash[:notice] = "Your HipChat account has been reset, please try logging in again."
    else
      flash[:alert] = "Sorry but your HipChat account could not be reset. Please contact josh@nreduce.com"
    end
    redirect_to :action => :chat
  end

    # multi-page process that any new mentor has to go through
  def onboard
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

  def load_user_if_me_or_current
    @user = current_user if params[:id].blank?
    @user = current_user if params[:id] == 'me'
    
  end

  def redirect_unless_authorized_for_user(user)
    unless current_user.id == user.id or current_user.admin?
      redirect_to '/'
      return false
    end
    true
  end
end
