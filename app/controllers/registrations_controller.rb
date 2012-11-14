class RegistrationsController < Devise::RegistrationsController
  around_filter :record_user_action, :only => [:new, :create]
  before_filter :run_ab_test, :only => [:new, :create]

  def new
    super
  end

  def create
    super
    session[:omniauth] = session[:password_not_required] = nil unless @user.new_record?
  end

  def edit
    redirect_to edit_user_path(current_user)
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
    @password_not_required = session[:password_not_required]
    if session[:invite_id].present?
      @invite_flow = true
      i = Invite.find(session[:invite_id])
      @user.startup = i.startup if i.present? && i.invite_type == Invite::TEAM_MEMBER && i.startup.present?
    end
    if params[:ojf].present? || @invite_flow
      @other_join_flow = true
    else
      @startup_join_flow = true
      @user.startup = Startup.new unless @user.startup.present?
      @user.startup.attributes = params[:startup] if params[:startup].present?
      @user.startup.in_signup_flow = true
      @user.roles << :entrepreneur
    end
  end
end