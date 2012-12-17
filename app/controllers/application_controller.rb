class ApplicationController < ActionController::Base
  around_filter :record_user_action, :only => [:ciao]
  before_filter :hc_url_fix
  before_filter :load_notifications_and_requests
  before_filter :authenticate_if_staging
  protect_from_forgery

  #link_to title, capture_and_login_path(:redirect_to => request.fullpath), options

  # Visit an external site
  def ciao
    redirect_to '/' && return if params[:url].blank?
    @ua = {:action => UserAction.id_for('external_url'), :data => {:source => params[:source]}}
    url = Base64.decode64(params[:url])
    url = "http://#{url}" unless url.match(/https?:\/\//) != nil
    redirect_to url
  end

  def capture_and_login
    session[:password_not_required] = true
    session[:redirect_to] = params[:redirect_to]
    redirect_to '/auth/twitter'
  end

  # Path for people joining from homepage - so we can do any custom redirects
  def join
    redirect_to '/auth/linkedin'
  end

  protected

  # Loads users and adds them to @users_by_id hash. Can be called multiple times to add users to hash
  def store_users_by_ids(users = [])
    @users_by_id ||= {}
    @users_by_id.merge!(Hash.by_key(users, :id))
  end

  def store_users_by_startup_id(users = [])
    @users_by_startup_id ||= {}
    users.each{|u| @users_by_startup_id[u.startup_id] ||= []; @users_by_startup_id[u.startup_id] << u }
  end

  def load_notifications_and_requests
    if user_signed_in?
      @entity = current_user.entrepreneur? && current_user.startup.present? ? current_user.startup : current_user

      @notifications = current_user.notifications.where("action != 'relationship_request'").ordered.limit(20).where(['created_at > ?', Time.now - 2.weeks]).all
      @unread_notifications_count = @notifications.present? ? @notifications.inject(0){|r,e| r += 1 if e.unread?; r } : 0

      @relationship_requests = @entity.pending_relationships.order('created_at DESC').includes(:entity).all
      @new_relationships_count = @relationship_requests.present? ? @relationship_requests.inject(0){|r,e| r += 1 if !e.seen_by?(current_user.id); r } : 0

      load_recent_conversations(100)
    end
  end

  def load_recent_conversations(limit = 20)
    @conversation_statuses = ConversationStatus.where(:user_id => current_user.id).with_folder(:inbox).includes(:conversation).order('conversations.updated_at DESC').limit(limit)
    @unread_conversations_count = 0
    @conversations = []
    @latest_message_by_conversation = {}
    if @conversation_statuses.size > 0
      user_ids = []
      @conversation_statuses.each{|cs| @conversations << cs.conversation; user_ids += cs.conversation.participant_ids }
      @latest_message_by_conversation = Hash.by_key(Message.where(:id => @conversations.map{|c| c.latest_message_id }), :conversation_id)
      # don't count message as new if from this user
      @conversation_statuses.each{|cs| @unread_conversations_count += 1 if cs.unseen? && @latest_message_by_conversation[cs.conversation_id].from_id != current_user.id }
      
      store_users_by_ids(User.where(:id => user_ids.uniq).includes(:startup))
    end
  end

  # For A/B testing - retains session data to make sure it sends the person to the same segment every time
  # Add this as a before filter to run a test on that action - right now it only supports one test at a time
  # Returns symbol: :a or :b
  def run_ab_test
    @ab_test_id = 1
    @ab_test_version = AbTest.version_for_session_id(@ab_test_id, request.session_options[:id])
  end

  def hc_url_fix
    request.format = :html if request.format.to_s.include? 'hc/url'
  end

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
        return accept_invite_path(:id => i.code)
      else
        session[:invite_id] = nil
        flash[:alert] = "The invite you tried to use is for #{i.email} - please sign in with that account if you want to accept it."
        return root_path
      end
    else
      if session[:redirect_to].present?
        tmp = session[:redirect_to]
        session[:redirect_to] = nil
        return tmp
      else
        super(resource)
      end
    end
  end

  # use an around_filter
  def record_user_action
    # initialize session now so we have a session id to use for a/b test
    session[:foo] = nil
    return true if @ua
    #Timecop.freeze Checkin.next_checkin_due_at(current_user.startup.checkin_offset) - 1.hour if Rails.env.development?
    #Timecop.return
    started = Time.now
    yield
    begin
      return true if @ua == false # set @ua to false if you don't want to record action
      # Don't store rackspace agent
      return true if request.env['HTTP_USER_AGENT'].present? && request.env['HTTP_USER_AGENT'].match(/^Rackspace/) != nil
      @ua ||= {}
      # for user tracking
      elapsed = Time.now - started
      @ua[:action] ||= UserAction.id_for("#{controller_name}_#{action_name}")
      @ua[:ip] = request.remote_ip
      @ua[:session_id] = request.session_options[:id]
      @ua[:time_taken] = elapsed
      @ua[:browser] = request.env['HTTP_USER_AGENT']
      @ua[:user_id] ||= current_user.id if user_signed_in?
      @ua[:created_at] = Time.now
      @ua[:url_path] = request.env['REQUEST_PATH']
      if @ab_test_id.present?
        @ua[:ab_test_id] =  @ab_test_id
        # Allow override from params so I can test when coming in from registration form
        @ua[:ab_test_version] = params[:ab_test_version] || @ab_test_version
      end
      user_action = UserAction.new(@ua)
      user_action.save!
    rescue => error
      logger.info "UserAction save error: #{error}"
      # do nothing
    end
  end

  # This method ensures that a user's account has been setup. If not, redirects to correct action
  def redirect_for_setup_and_onboarding
    controller_action_arr = [controller_name.to_sym, action_name.to_sym]
    # Don't redirect if here for demo day
    return true if [:questions, :demo_day].include?(controller_action_arr.first)
    if current_user.account_setup?
      return true
    else
      @account_setup_action = current_user.account_setup_action
      if @account_setup_action.blank?
        # If for some reason account setup action is blank - redirect to user account page
        return if controller_action_arr == [:users, :show]
        redirect_to current_user
        return
      end

      # Account is not set up
      @hide_nav = true
      @setup = true unless [:account_type, :spectator, :start].include?(@account_setup_action.last)
     
      if @account_setup_action.first == :complete
        flash[:notice] = "Thanks for setting up your account!"
        redirect_to '/'
        return
      end
      # if we're in the right place, don't do anything
      return true if controller_action_arr == @account_setup_action
      # Allow create/update actions
      if controller_action_arr.first == @account_setup_action.first
        return true if @account_setup_action.first == :onboard
        return true if @account_setup_action.last == :edit and action_name.to_sym == :update
        return true if @account_setup_action.last == :new and [:create, :edit].include?(controller_action_arr.last)
      end
      # otherwise redirect to correct controller/action
      prms = {:controller => @account_setup_action.first, :action => @account_setup_action.last}
      # use obfuscated id
      prms[:id] = current_user.to_param if prms[:controller] == :users
      prms[:id] = current_user.startup.to_param if prms[:controller] == :startups
      redirect_to prms
      #end
    end
    false
  end

  def load_requested_or_users_startup
    @startup = Startup.find_by_obfuscated_id(params[:startup_id]) unless params[:startup_id].blank?
    @startup ||= current_user.startup if params[:id].blank? and !current_user.startup_id.blank?
    # Make sure they have a goal set
    if current_user.startup.present?
      # Localize time to startup
      Time.zone = current_user.startup.time_zone if current_user.startup.time_zone.present?
      if controller_name.to_sym != :onboard && current_user.startup.current_checkin.blank?
        @force_checkin = true
        @checkin = Checkin.new(:startup => current_user.startup)
      end
    end
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

  # DEMO-DAY related methods

  # Pass in a time object to only_if_any_since to load only if there are any new questions since that time
  def load_questions_for_startup(startup, only_if_any_since = nil)
    @startup = startup
    @question = Question.new(:startup => startup)
    if only_if_any_since.present?
      # limit to questions only since a certain time
      return false if Question.last_changed_at_for_startup(startup).utc < only_if_any_since
    end
    @questions = Question.unanswered_for_startup(startup).order('created_at').includes(:user, :startup)
    #@questions = Question.unanswered_for_startup(startup).order('followers_count DESC').includes(:user, :startup)
    # Mark questions as unseen
    @questions.each{|q| q.unseen = true if q.updated_at.utc > only_if_any_since && (user_signed_in? ? current_user.id != q.user_id : true) } if only_if_any_since.present?
    # Extract current question
    @current_question = @questions.shift if @questions.present?
    true
  end

    # Loads the demo day, and redirects to the before or after page if it's not in the time window
  def load_and_validate_demo_day
    # if is_staging?
    #   @demo_day = DemoDay.where(:day => "2012-10-03").first
    # else
    #   @demo_day = DemoDay.next_or_current
    # end
    #@demo_day = DemoDay.next_or_current
    @demo_day = DemoDay.where(:day => "2012-10-03").first
    # if admin or demo day participant let them in early
    if user_signed_in? && (current_user.admin? || (current_user.startup_id.present? && @demo_day.startup_ids.include?(current_user.startup_id)))
      if Time.now > @demo_day.ends_at
        @next_demo_day = @demo_day.next_demo_day
        @after = true
      end
    else
      if Time.now < @demo_day.starts_at
        @before = true
      elsif Time.now > @demo_day.ends_at
        @after = true
        @next_demo_day = @demo_day.next_demo_day
      end
      if @before || @after
        # If ajax request do nothing
        if request.xhr?
          render :nothing => true
        else # Otherwise redirect to main page to then render before/after pages
          redirect_to demo_day_index_path unless [[:demo_day, :index], [:demo_day, :show]].include?([controller_name.to_sym, action_name.to_sym])
        end
      else
        @no_twitter = true if user_signed_in? && current_user.twitter_authentication.blank?
      end
    end
  end

  def initialize_tokbox_session(startup, force_new_session = false)
    # Initialize tokbox session
    @tokbox = OpenTok::OpenTokSDK.new Settings.apis.tokbox.key, Settings.apis.tokbox.secret

    # Create session id unless startup already has one
    if startup.tokbox_session_id.blank? || force_new_session
      startup.tokbox_session_id = @tokbox.createSession(request.remote_ip).to_s
      startup.save
    end
    @tokbox_session_id = startup.tokbox_session_id

    if user_signed_in? && startup.id == current_user.startup_id
      role = OpenTok::RoleConstants::MODERATOR # Other role: OpenTok::RoleConstants::PUBLISHER
      @owner = true
    else
      role = OpenTok::RoleConstants::SUBSCRIBER
    end
    @tokbox_token = @tokbox.generateToken :session_id => @tokbox_session_id, :role => role, :connection_data => user_signed_in? ? "uid=#{current_user.id}" : ''
  end

  private

  def is_staging?
    ['staging.nreduce.com'].include?(request.host)
  end

  def only_allow_in_staging
    unless is_staging?
      redirect_to '/'
      return false
    end
    true
  end

  def authenticate_if_staging
    if is_staging?
      authenticate_or_request_with_http_basic do |username, password|
        username == Settings.staging.username && password == Settings.staging.password
      end
    else
      true
    end
  end

  def require_ssl
    # SSL needs to be forced if the server is in production and the request is not already SSL
    if Rails.env.production? && !request.ssl?
      flash.keep
      redirect_to :protocol => "https://", :host => Settings.ssl_host
      return false
    end
    true
  end
end
