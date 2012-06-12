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

  before_filter :current_startup_required, :only => [:chat]

  def chat
    @user = current_user
    @user.generate_hipchat! unless @user.hipchat?
  end

  protected

  def redirect_unless_user_can_view_user(user)
    unless current_user.id == user.id or current_user.admin?
      redirect_to '/'
      return false
    end
    true
  end
end
