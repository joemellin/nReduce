class UsersController < ApplicationController
  around_filter :record_user_action, :except => [:reset_hipchat_account]
  before_filter :login_required

  def complete_account
    @user = current_user
  end

  def show
    @user = current_user if params[:id] == 'me'
    @user ||= User.find(params[:id])
    
    # Load current invite if they have one  - don't search by email because that opens security hole where a user can sign up with an email they don't own and get invite - really should be verifying email
    if @user.id == current_user.id
      @current_invite = Invite.not_accepted.where(:to_id => current_user.id).first
      @current_invite = nil if @current_invite and !@current_invite.active?
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = "Your account has been updated!"
      render :action => :show
    else
      if params[:complete_account].to_s == 'true'
        render :action => :complete_account
      else
        render :action => :edit
      end
    end
  end

  def onboard
    render :action => "onboard/#{params[:step]}"
  end

  before_filter :current_startup_and_checkin_required, :only => [:chat, :reset_hipchat_account]

  def chat
    @user = current_user
    @user.generate_hipchat! unless @user.hipchat?
  end

  def reset_hipchat_account
    @user = current_user
    if @user.reset_hipchat_account!
      flash[:notice] = "Your HipChat account has been reset, please try logging in again."
    else
      flash[:alert] = "Sorry but your HipChat account could not be reset. Please contact josh@nreduce.com"
    end
    redirect_to :action => :chat
  end

  protected

  def redirect_unless_authorized_for_user(user)
    unless current_user.id == user.id or current_user.admin?
      redirect_to '/'
      return false
    end
    true
  end
end
