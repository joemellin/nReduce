class DemoDayController < ApplicationController
  before_filter :load_and_validate_demo_day

  def index
    if @before || @after
      render :action => :before if @before
      render :action => :after if @after
      return
    end
  end

    # Show a specific company
  def show
    @startup = Startup.find_by_obfuscated_id(params[:id])
    
    # Initialize tokbox session
    @tokbox = OpenTok::OpenTokSDK.new Settings.apis.tokbox.key, Settings.apis.tokbox.secret

    # Create session id unless startup already has one
    if @startup.tokbox_session_id.blank?
      @startup.tokbox_session_id = @tokbox.createSession(request.remote_ip).to_s
      @startup.save
    end
    @tokbox_session_id = @startup.tokbox_session_id

    # Define correct role so user has controls over video stream
    if current_user.admin?
      role = OpenTok::RoleConstants::MODERATOR
      @owner = true
    elsif @startup.id == current_user.startup_id
      role = OpenTok::RoleConstants::PUBLISHER
      @owner = true
    else
      role = OpenTok::RoleConstants::SUBSCRIBER
    end
    @tokbox_token = @tokbox.generateToken :session_id => @tokbox_session_id, :role => role, :connection_data => "uid=#{current_user.id}"

    load_questions_for_startup(@startup)

    redirect_to :action => :index && return unless @demo_day.startup_ids.include?(@startup.id)
  end
end
