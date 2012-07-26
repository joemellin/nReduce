class Admin::UsersController < ApplicationController
  before_filter :admin_required

  def index
    @users = User.with_any_onboarded(:startup, :mentor, :nreduce_mentor).without_setup(:welcome).where('created_at > "2012-07-24"').order('created_at DESC').includes(:startup).paginate(:page => params[:page], :per_page => 50)
  end

  # Sign in as a different user
  def sign_in_as
    @user = User.find(params[:id])
    sign_out(current_user)
    sign_in(@user)
    flash[:notice] = "You are now signed in as #{@user.name}. Remember to sign out when you're done."
    redirect_to @user
  end

  def approve
    flash[:notice] = "User account has been set up" if @user.setup_complete!
    redirect_to @user
  end
end