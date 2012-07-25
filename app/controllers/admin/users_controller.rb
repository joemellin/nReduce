class Admin::UsersController < ApplicationController
  before_filter :admin_required

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