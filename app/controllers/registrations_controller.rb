class RegistrationsController < Devise::RegistrationsController
  around_filter :record_user_action, :only => [:new, :create]

  def new
    super
  end

  def create
    super
    session[:omniauth] = nil unless @user.new_record?
  end
  
  private

  def build_resource(*args)
    super
    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @user.valid?
      @omniauth = true
    end
    @user.email = session[:sign_in_up_email] unless @user.blank? or session[:sign_in_up_email].blank?
    @user.geocode_from_ip(request.remote_ip) if @user.location.blank?
    @hide_twitter = true if !session[:invite_id].blank?
  end
end