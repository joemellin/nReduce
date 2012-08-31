class ApplicationController < ActionController::Base
  before_filter :show_nstar_banner
  #before_filter :block_ips
  protect_from_forgery

  # Visit an external site
  def ciao
    redirect_to '/' && return if params[:url].blank?
    url = Base64.decode64(params[:url])
    url = "http://#{url}" unless url.match(/https?:\/\//) != nil
    redirect_to url
  end

  protected

  def show_nstar_banner
    @show_nstar_banner = (controller_name == 'pages' and action_name != 'community_guidelines')
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, params)
  end

  # User will always be able to see their account so redirect them here
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to (user_signed_in? ? current_user : '/'), :alert => exception.message
  end

    # Override sign in path so we can accept invite if they have one
  def after_sign_in_path_for(resource)
    session[:sign_in_up_email] = nil
    if !session[:invite_id].blank?
      i = Invite.find(session[:invite_id])
      if current_user.email == i.email
        accept_invite_path(:id => i.code)
      else
        session[:invite_id] = nil
        flash[:alert] = "The invite you tried to use is for #{i.email} - please sign in with that account if you want to accept it."
        root_path
      end
    else
      root_path
    end
  end

  # use an around_filter
  def record_user_action
    return true if @ua
    started = Time.now
    yield
    begin
      return
      @ua ||= {}
      # for user tracking
      elapsed = Time.now - started
      @ua[:action] = UserAction.id_for("#{controller_name}_#{action_name}")
      @ua[:ip] = request.remote_ip
      @ua[:time_taken] = elapsed
      @ua[:browser] = request.env['HTTP_USER_AGENT']
      @ua[:user_id] ||= current_user.id if user_signed_in?
      @ua[:created_at] = Time.now
      @ua[:url_path] = request.env['REQUEST_PATH']
      user_action = UserAction.new(@ua)
      user_action.save!
    rescue => error
      logger.info "UserAction save error: #{error}"
      # do nothing
    end
  end

  # This method ensures that a user's account has been setup. If not, redirects to correct action
  def redirect_for_setup_and_onboarding
    if current_user.account_setup?
      return true
    else
      @hide_nav = true
      controller_action_arr = [controller_name.to_sym, action_name.to_sym]
      @account_setup_action = current_user.account_setup_action
      if @account_setup_action.blank?
        # If for some reason account setup action is blank - redirect to user account page
        return if controller_action_arr == [:users, :show]
        redirect_to current_user
        return
      end
      @setup = true unless [:account_type, :spectator].include?(@account_setup_action.last)
      if @account_setup_action.first == :complete
        flash[:notice] = "Thanks for setting up your account!"
        redirect_to '/'
        return
      end
      # if we're in the right place, don't do anything
      return true if controller_action_arr == @account_setup_action
      # Allow them to choose account type again / invite team members
      return true if [[:users, :account_type], [:invites, :create]].include?(controller_action_arr)
      # Allow create/update actions
      if controller_action_arr.first == @account_setup_action.first
        return true if @account_setup_action.last == :edit and action_name.to_sym == :update
        return true if @account_setup_action.last == :new and [:create, :edit].include?(controller_action_arr.last)
      end
      # onboarding has a few actions involved, so if they're in onboarding don't change action
      return true if [controller_action_arr.first, @account_setup_action.first] == [:onboard, :onboard]
      # otherwise redirect to correct controller/action
      prms = {:controller => @account_setup_action.first, :action => @account_setup_action.last}
      prms[:id] = current_user.to_param if prms[:controller] == :users
      prms[:id] = current_user.startup.to_param if prms[:controller] == :startups
      redirect_to prms
    end
    false
  end

  def block_ips
    if request.remote_ip == '75.161.16.187'
      render :nothing => true
      return
    end
  end

  def load_requested_or_users_startup
    @startup = Startup.find_by_obfuscated_id(params[:startup_id]) unless params[:startup_id].blank?
    @startup ||= current_user.startup if params[:id].blank? and !current_user.startup_id.blank?
  end

  def login_required
    if authenticate_user!
      return redirect_for_setup_and_onboarding
    else
      return false
    end
  end

  def admin_required
    if login_required
      if current_user.admin?
        return true
      else
        flash[:notice] = "You don't have admin access"
        redirect_to '/'
      end
    end
    return false
  end

  def current_startup_required
    @current_startup = current_user.startup if user_signed_in? and !current_user.startup.blank?
    if @current_startup.blank?
      redirect_to new_startup_path
      return false
    end
    true
  end
  
  def meeting_organizer_required
    @meeting = Meeting.find(params[:meeting_id]) unless params[:meeting_id].blank?
    @meeting ||= Meeting.find(params[:id]) unless params[:id].blank?
    return false if @meeting.blank?
    if (@meeting.organizer_id != current_user.id) and !current_user.admin?
      flash[:alert] = "You don't have permission to mesage attendees"
      redirect_to @meeting
      return false
    else
      return true
    end
  end

  # use stored invite id and accept
  def accept_invite_for_user(user)
    invite = Invite.find(session[:invite_id])
    res = invite.accepted_by(user)
    session[:invite_id] = nil
    res
  end

  protected

  def load_obfuscated_user
    begin
      @user = User.find_by_obfuscated_id(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to '/'
      return
    end
  end

  def load_obfuscated_startup(ignore_bare_id = false)
    begin
      @startup ||= Startup.find_by_obfuscated_id(params[:id]) unless ignore_bare_id || params[:id].blank?
      @startup ||= Startup.find_by_obfuscated_id(params[:startup_id]) unless params[:startup_id].blank?
    rescue ActiveRecord::RecordNotFound
      redirect_to '/'
      return
    end
  end

  # Only load based on startup_id instead of also checking id - used when in a nested controller
  def load_obfuscated_startup_nested
    load_obfuscated_startup(true)
  end
  
  def redirect_if_no_startup
    if @startup.blank?
      redirect_to current_user
      return false
    end
    true
  end
end
