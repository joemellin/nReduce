class SessionsController < Devise::SessionsController
  def new
    logger.info 'HERE'
    super
    resource.email = session[:sign_in_up_email] unless resource.blank? or session[:sign_in_up_email].blank?
  end
end