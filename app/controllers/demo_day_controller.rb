class DemoDayController < ApplicationController
  #before_filter :only_allow_in_staging
  before_filter :login_required, :only => [:attend]
  before_filter :load_and_validate_demo_day

  def index
    if @before
      render :action => :before if @before
      #render :action => :after if @after
      return
    end
    @question_count = Question.group('startup_id').unanswered.count
  end

    # Show a specific company
  def show
    if @demo_day.startup_ids[params[:id].to_i].present?
      @startup = Startup.find(@demo_day.startup_ids[params[:id].to_i])
      # Load all checkins made before demo day
      @checkins = @startup.checkins.where(['created_at < ?', "#{@demo_day.day} 00:00:00"]).ordered.includes(:before_video, :after_video)
    else
      redirect_to :action => :index
      return
    end
    
    # Initialize tokbox session
    @tokbox = OpenTok::OpenTokSDK.new Settings.apis.tokbox.key, Settings.apis.tokbox.secret

    # Create session id unless startup already has one
    if @startup.tokbox_session_id.blank?
      @startup.tokbox_session_id = @tokbox.createSession(request.remote_ip).to_s
      @startup.save
    end
    @tokbox_session_id = @startup.tokbox_session_id

    # Define correct role so user has controls over video stream
    #if user_signed_in? && current_user.admin?
    #  role = OpenTok::RoleConstants::MODERATOR
    #  @owner = true
    if user_signed_in? && @startup.id == current_user.startup_id
      role = OpenTok::RoleConstants::MODERATOR #OpenTok::RoleConstants::PUBLISHER
      @owner = true
    else
      role = OpenTok::RoleConstants::SUBSCRIBER
    end
    @tokbox_token = @tokbox.generateToken :session_id => @tokbox_session_id, :role => role, :connection_data => user_signed_in? ? "uid=#{current_user.id}" : ''
    
    load_questions_for_startup(@startup)
    
    @num_checkins = @startup.checkins.count
    @num_awesomes = @startup.awesomes.count
    @screenshots = @startup.screenshots.ordered

    @video = @demo_day.video_for_startup(@startup)
  end

  # Register that you've attended demo day
  def attend
    @demo_day.add_attendee!(current_user)
    redirect_to :action => :index
  end
end
