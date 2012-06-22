class SessionsController < Devise::SessionsController
  def new
    @show_sign_in = true if params[:s] and params[:s].to_s == '1'
    super
  end

  protected

  def build_resource(*args)
    super
    @user.email = session[:sign_in_up_email] unless @user.blank? or session[:sign_in_up_email].blank?
  end
end