class RegistrationsController < Devise::RegistrationsController
  def new
    super
    @omniauth = !session[:omniauth].blank?
    @user.geocode_from_ip(request.remote_ip) if @user.location.blank?
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
    end
  end
end