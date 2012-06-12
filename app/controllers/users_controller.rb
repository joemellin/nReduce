class UsersController < ApplicationController
  before_filter :login_required

  def show
    @user = current_user

  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      render :action => :show
    else
      render :action => :edit
    end
  end

  before_filter :current_startup_required, :only => [:chat, :reset_hipchat_account]

  def chat
    @user = current_user
    @user.generate_hipchat! unless @user.hipchat?
  end

  def reset_hipchat_account
    @user = current_user
    if @user.reset_hipchat_account!
      flash[:notice] = "Your HipChat account has been reset, please try logging in again."
    else
      flash[:error] = "Sorry but your HipChat account could not be reset. Please contact josh@nreduce.com"
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
