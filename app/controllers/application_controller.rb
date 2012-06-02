class ApplicationController < ActionController::Base
  # protect_from_forgery


  protected

  def partner_required
    if logged_in? and current_auth.partner?
      return true
    else
      save_url
      flash[:notice] = "Partner access is required to view this page."
      redirect_to "/"
      return false
    end
  end

  def login_required
    if logged_in?
      return true
    else
      save_url
      redirect_to "/login"
      return false
    end
  end

  def startup_required
    return unless login_required

    if current_startup.present?
      return true
    else
      flash[:alert] = "Your twitter handle is not currently associated with a startup team."
      redirect_to "/"
      return false
    end
  end

  def mentor_required
    return unless login_required

    if current_mentor.present?
      return true
    else
      flash[:alert] = "Your twitter handle is not currently associated with a registered mentor."
      redirect_to "/"
      return false
    end
  end

  def investor_required
    return unless login_required

    if current_investor.present?
      return true
    else
      flash[:alert] = "Your twitter handle is not currently associated with a registered investor."
      redirect_to "/"
      return false
    end
  end

  helper_method :logged_in?
  def logged_in?
    current_auth.present?
  end

  helper_method :is_startup?
  def is_startup?
    true
    # current_auth.present? && current_auth.matching_startup.present?
  end

  helper_method :current_auth
  def current_auth
    @current_auth ||= begin
      Authentication.by_id(session[:current_auth]) if session[:current_auth].present?
    end
  end

  def current_auth=(auth)
    session[:current_auth] = auth.id.to_s
  end

  helper_method :current_startup
  def current_startup
    return unless current_auth.present?
    @current_startup ||= begin
      current_auth.matching_startup
    end
  end

  helper_method :current_mentor
  def current_mentor
    return unless current_auth.present?
    @current_mentor ||= begin
      current_auth.matching_mentor
    end
  end

  helper_method :current_investor
  def current_investor
    return unless current_auth.present?
    @current_investor ||= begin
      current_auth.matching_investor
    end
  end

  def save_url
    current_path = request.path

    if current_path != "" and current_path != "/"
      # save url in session
      session[:redirect_url] = current_path
    end
  end

  def redirect_back
    redirect_url = session[:redirect_url]
    if redirect_url.present?
      session[:redirect_url] = nil
      redirect_to redirect_url
    else
      redirect_to "/"
    end
  end

  def token_user
    return unless session[:token_user]

    @token_user ||= begin
      User.by_id(session[:token_user])
    end
  end
end
