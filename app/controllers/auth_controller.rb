class AuthController < ApplicationController
  def login

  end

  def create
    auth = Authentication.from_omniauth(omniauth_data)

    self.current_auth = auth

    flash[:notice] = "You are now logged in via #{auth.provider}."
    redirect_back
  end

  def failure
    flash[:alert] = "Unable to connect"
    redirect_to "/"
  end

  def destroy
    session[:current_auth] = nil
    flash[:notice] = "You are now logged out."
    redirect_to "/"
  end

  def vanilla_connect
    user = {}

    if logged_in? and is_startup?
      user["uniqueid"] = current_auth.id.to_s
      user["name"] = current_auth.name
      user["email"] = current_auth.email
      user["photourl"] = current_auth.photo_url
    end

    render :text => Vanilla::JsConnect.js_response(user, params, Settings.vanilla.client_id, Settings.vanilla.secret, Settings.vanilla.secure)
  end

  # show your "user profile"
  def show

  end

  # edit your user information
  def edit

  end

  # update user information
  def update

  end

  protected

  def omniauth_data
    request.env['omniauth.auth']
  end

end
