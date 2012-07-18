class AuthenticationsController < ApplicationController
  include Devise::Controllers::Rememberable # included to set cookie manually
  around_filter :record_user_action, :only => [:create, :failure, :destroy]
  load_and_authorize_resource :only => [:index, :destroy]

  def index
    redirect_to user_signed_in? ? current_user : '/'
  end

  def create
    omniauth = request.env["omniauth.auth"]
   # @ua = {:action => UserAction.id_for('add_authentication'), :data => {:provider => omniauth['provider']}}
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])
    if authentication
      authentication.update_attributes(:token => omniauth['credentials']['token'], :secret => omniauth['credentials']['secret']) if omniauth['credentials'] && !omniauth['credentials']['token'].blank?
      #flash[:notice] = "Signed in successfully."
      remember_me(authentication.user) # set remember me cookie
      sign_in_and_redirect(:user, authentication.user)
    elsif current_user # already a signed in user
      current_user.apply_omniauth(omniauth)
      current_user.geocode_from_ip(request.remote_ip) if current_user.location.blank?
      if current_user.save
        flash[:notice] = "Authentication successful."
      else
        flash[:alert] = "Sorry but you could't be authenticated. Please try again:"
      end
      redirect_to current_user
    else
      user = User.new
      user.apply_omniauth(omniauth)
      if user.save
        #flash[:notice] = "Signed in successfully."
        remember_me(user) # set remember me cookie
        sign_in_and_redirect(:user, user)
      else
        logger.info "user inspect: #{user.inspect} with errors #{user.errors.full_messages}"
        session[:omniauth] = omniauth.except('extra')
        redirect_to new_user_registration_url
      end
    end
  end
  
  def failure
    flash[:alert] = "Sorry but you could't be authenticated. Please try again:"
    @ua = {:data => {:message => params[:message]}}
    redirect_to new_user_registration_url
  end

  def destroy
    @authentication.destroy
    flash[:notice] = "Successfully destroyed authentication."
    redirect_to authentications_url
  end

  protected

  # This is necessary since Rails 3.0.4
  # See https://github.com/intridea/omniauth/issues/185
  # and http://www.arailsdemo.com/posts/44
  def handle_unverified_request
    true
  end
end
