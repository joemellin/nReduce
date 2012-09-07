class SessionsController < Devise::SessionsController
  def new
    super
    @show_sign_in = true if params[:s].present? and params[:s].to_s == '1'
  end

  protected

  def build_resource(*args)
    super
    @user.email = session[:sign_in_up_email] unless @user.blank? or session[:sign_in_up_email].blank?
  end
end