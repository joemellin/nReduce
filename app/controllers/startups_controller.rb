class StartupsController < ApplicationController
  #around_filter :record_user_action, :except => [:onboard_next, :stats]
  before_filter :login_required
  before_filter :load_requested_or_users_startup, :except => [:index, :invite, :stats, :investment_profile, :search]
  load_and_authorize_resource :except => [:index, :stats, :invite, :show, :invite_team_members, :intro_video, :mini_profile, :investment_profile, :search]
  before_filter :load_obfuscated_startup, :only => [:show, :invite_team_members, :before_video, :intro_video, :mini_profile, :investment_profile]
  authorize_resource :only => [:show, :invite_team_members, :before_video, :intro_video, :mini_profile]
  before_filter :redirect_if_no_startup, :except => [:index, :invite, :search]

  def index
    redirect_to '/'
  end

  def new
    redirect_to :action => :edit unless @startup.new_record?
  end

  def invite_ajax
    @invite = Invite.new(params[:startup][:invite])
    @success = true if @invite.save
    respond_to do |format|
      format.js { render :action => :invite_ajax }
    end
  end

    # Invite startups
  def invite
    if request.post?
      unless params[:invite].blank?
        @invite = Invite.new(params[:invite])
        @invite.startup = @startup if @startup
        @invite.from = current_user
        @invite.invite_type = Invite::STARTUP
        if @invite.save
          flash[:notice] = "Thanks! #{@invite.email} has been invited."
          @invite = Invite.new # reset for next invite
        else
          flash[:alert] = "#{@invite.errors.full_messages.join('. ')}."
        end
        @modal = true if request.xhr?
        respond_to do |format|
          format.js { render :action => 'update_invite_modal' }
          format.html
        end
      end
      # They're in setup, and said they're done inviting
      if params[:done]
        current_user.invited_startups!
        redirect_to '/'
        return
      end
    end
    @invites = current_user.sent_invites
  end

  # Two-step invite
  # 1) Check name to see if they are already in the system - if so just create relationship
  # 2) Otherwise do traditional path
  def invite_with_confirm
    startup = Startup.where(:name => params[:startup_name]).first if params[:startup_name].present?
    @invite = Invite.new
    if startup.present?
      @invite.startup = startup 
      @invite.to = startup.team_members.first
    end
    @invite.from = current_user
    # run validations to assign from/to
    @invite.valid?
    logger.info @invite.inspect
    if !@invite.from.blank? && !@invite.from.startup.blank? && !@invite.startup.blank? && !@invite.to.blank?
      @relationship = Relationship.new(:entity => @invite.from.startup, :connected_with => @invite.startup)
      @relationship.context << :startup_startup
    end
    @modal = true
    respond_to do |format|
      format.js { render :action => 'update_invite_modal' }
      format.html
    end
  end

  def create
    @startup = Startup.new(params[:startup])
    if @startup.save
      current_user.startup = @startup
      if current_user.save
        #flash[:notice] = "Startup profile has been saved."
        redirect_to :action => :edit
      else
        render :new
      end
    else
      render :new
    end
  end

  def show
    @owner = true if user_signed_in? and (@startup.id == current_user.startup_id)
    @can_view_checkin_details = can? :read, Checkin.new(:startup => @startup)
    @num_checkins = @startup.checkins.count
    @num_awesomes = @startup.awesomes.count
    @checkins = @startup.checkins.ordered.includes(:before_video, :video)
    if current_user.entrepreneur?
      @entity = current_user.startup unless current_user.startup.blank?
    else
      @entity = current_user
    end
    if params[:suggested] # we need to look for a relationship in the opposite direction if suggested
      @relationship = Relationship.between(@entity, @startup)
      @pending_relationship = nil
    else
      @relationship = Relationship.between(@startup, @entity)
      @pending_relationship = Relationship.between(@entity, @startup)
    end
  end

    # mini profile for ajax requests
  def mini_profile
    @num_checkins = @startup.checkins.count
    @num_awesomes = @startup.awesomes.count
    if current_user.entrepreneur?
      @entity = current_user.startup unless current_user.startup.blank?
    else
      @entity = current_user
    end
    @relationship = Relationship.between(@startup, @entity)
    respond_to do |format|
      format.js
      format.html { render :nothing => true }
    end
  end
  
  #
  # Actions for user's startup
  #

  def edit
    @profile_elements = @startup.profile_elements(true)
    @profile_completeness_percent = (@startup.profile_completeness_percent * 100).round
    @screenshots = @startup.screenshots.ordered
    # Build up to 4 screenshots
    @screenshots.size.upto(Startup::NUM_SCREENSHOTS - 1).each{|i| @startup.screenshots.build }
    @startup.intro_video = ViddlerVideo.new if @startup.intro_video.blank?
    @startup.pitch_video = ViddlerVideo.new if @startup.pitch_video.blank?
  end

  def update
    @startup.attributes = params[:startup]
    @dont_render_form = params[:dont_render_form].present? ? true : false
    if @startup.save
      respond_to do |format|
        format.js
        format.html { redirect_to @startup }
      end
    else
      @message = "Could not save: #{@startup.errors.full_messages.join(', ')}."
      @profile_elements = @startup.profile_elements
      @profile_completeness_percent = (@startup.profile_completeness_percent * 100).round
      respond_to do |format|
        format.js
        format.html { render :edit }
      end
    end
  end

  def invite_team_members
    if request.post?
      @startup.invited_team_members!
      redirect_to '/'
      return
    end
  end

  def add_invite_field
    @invite = Invite.new(:startup_id => @startup.id, :from_id => current_user.id)
    @c = params[:c] || 1
    respond_to do |format|
      format.js { render :action => :add_invite_field }
    end
  end

   # Start of setup flow - to get startup to post initial before video
  def before_video
  #if can? :before_video, @startup
    @before_disabled = false
    @after_disabled = true
    @hide_time = true
    @checkin = Checkin.new
    unless params[:checkin].blank?
      @checkin.attributes = params[:checkin]
      @checkin.startup = @startup
      if @checkin.before_completed? and @checkin.check_video_urls_are_valid and @checkin.save(:validate => false)
        redirect_to '/'
        return
      end
    end
    #else
    #  redirect_to '/'
    #  return
    #end
  end

  def intro_video
    @startups = Startup.with_intro_video.limit(6).order("RAND()")
    if params[:startup].present? && params[:startup][:intro_video_url].present?
      @startup.intro_video_url = params[:startup][:intro_video_url]
      if @startup.save
        redirect_to '/'
        return
      end
    end
  end

    # Removes a team member
  def remove_team_member
    u = User.find(params[:user_id])
    if @startup.id != u.startup_id
      flash[:alert] = "#{u.name} could not be removed because they aren't a member of your team."
    else
      u.startup_id = nil
      if u.save
        flash[:notice] = "#{u.name} has been removed from your team."
      else
        flash[:alert] = "Sorry, but #{u.name} could not be removed at this time."
      end
    end
    redirect_to edit_startup_path(@startup)
  end

  def investment_profile
    authorize! :manage, @startup
    @checkin_history = Checkin.history_for_startup(@startup)
    @screenshots = @startup.screenshots.ordered
    @instrument = @startup.instruments.first
    @measurements = @instrument.measurements.ordered_asc.all unless @instrument.blank?
    @videos = @startup.investor_videos
    @vimeo_js = true
  end

  def search
    @search = {:search_type => 'location'}
    if params[:search].present?
      # sanitize search params
      params[:search].select{|k,v| [:query, :industry_ids, :search_type].include?(k) }

      # save in session for pagination
      @search = params[:search]
    elsif params[:page].present? && session[:search].present?
      @search = session[:search]
    end

    # Force geocode from IP if no search + user doesn't hae location
    if @search[:search_type] == 'location' && @search[:query].blank?
      current_user.geocode_from_ip(request.remote_ip) unless current_user.geocoded?
      @search[:query] = current_user.location
    end

    session[:search] = @search

    @search[:page] = params[:page] || 1
    @search[:per_page] = 10
    @search[:industry_ids] ||= []

    @startups_by_id = Hash.by_key(Startup.where(:active => true), :id)
    if @search[:search_type] == 'location'
      origin = @search[:query].present? ? @search[:query] : [current_user.lat, current_user.lng]
      @results = User.geocoded.where(:startup_id => @startups_by_id.keys).group(:startup_id).order(:name).paginate(:page => params[:page] || 1, :per_page => 10) 
      # geocoder not working now: @results = User.geocoded.geo_scope(:origin => origin).where(:startup_id => @startups_by_id.keys).group(:startup_id).order(:distance).paginate(:page => params[:page] || 1, :per_page => 10) 
      startup_ids = @results.map{|s| s.startup_id }
    else
      @search_results = Startup.search do |s|
        s.fulltext(@search[:query], {:fields => :name}) if @search[:query].present? && @search[:search_type] == 'startup_name'
        s.fulltext(@search[:query], {:fields => :team_member_names}) if @search[:query].present? && @search[:search_type] == 'founder_name'
        s.with :active, true
        s.with :industry_ids, @search[:industry_ids].map{|id| id.to_i } if @search[:industry_ids].present?
        s.paginate :page => @search[:page], :per_page => @search[:per_page]
      end
      startup_ids = @search_results.hits.map{|s| s.stored(:id) }
      @results = @search_results.results
    end
    @num_checkins_by_startup = Checkin.where(:startup_id => startup_ids).group(:startup_id).count

    @tag_id_count = ActsAsTaggableOn::Tagging.where(:context => 'industries').where(:taggable_id => @startups_by_id.keys).group(:tag_id).count
    @sorted_tag_ids = @tag_id_count.sort{|a,b| a.last <=> b.last }.reverse.map{|id_count| id_count.first }
    @tags_by_id = Hash.by_key(ActsAsTaggableOn::Tag.where(:id => @sorted_tag_ids), :id)

  end

  #
  # ADMIN ONLY
  #

  before_filter :admin_required, :only => [:stats]

  def stats
    respond_to do |format|
      format.csv { send_data(Startup.generate_stats_csv,
                   :type => 'text/csv; charset=iso-8859-1; header=present',
                   :disposition => "attachment; filename=startup_stats_#{Date.today.to_s(:db)}.csv")
                 }
      format.html { render :nothing => true }
    end
  end

  protected

  def search_old
    if !params[:search].blank?
      # sanitize search params
      params[:search].select{|k,v| [:name, :meeting_id, :industries].include?(k) }

      # save in session for pagination
      @search = session[:search] = params[:search]
    elsif !params[:page].blank?
      @search = session[:search]
    end

    @search = {:query => params[:query], :page => 1, :per_page => 10}
    @search[:sort] ||= 'rating'

    # Have to pass context for block or else you can't access @search instance variable
    @search_results = Startup.search do |s|
      s.fulltext(@search[:query])
      s.with :onboarded, true
      s.with :meeting_id, @search[:meeting_id] unless @search[:meeting_id].blank?
      unless @search[:industries].blank?
        tag_ids = ActsAsTaggableOn::Tag.named_like_any_from_string(@search[:industries]).map{|t| t.id }
        s.with :industry_tag_ids, tag_ids unless tag_ids.blank?
      end
      if @search[:sort] == 'rating'
        s.order_by :rating, :desc
      else
        s.order_by @search[:sort]
      end
      s.paginate :page => @search[:page], :per_page => @search[:per_page]
    end


    # # Add conditions
    # # Ignore current user's startup
    # #if user_signed_in? and !current_user.startup_id.blank?
    # #  @startups = @startups.where("startups.id != '#{current_user.startup_id}'")
    # #end
    # unless @search[:name].blank?
    #   @startups = @startups.where(['startups.name LIKE ?', "%#{@search[:name]}%"])
    # end
    # unless @search[:meeting_id].blank?
    #   @startups = @startups.where(['startups.meeting_id = ?', @search[:meeting_id]])
    # end
    # unless @search[:industry_id].blank?
    #   @startups = @startups.where(['startups.industry_id = ?', @search[:industry_id]])
    # end
    @meetings_by_id = Meeting.location_name_by_id
    @tags_by_startup_id = Startup.tags_by_startup_id(@startups)

    # if current_user.mentor?
    #   @entity = current_user
    # elsif !current_user.startup.blank?
    #   @entity = current_user.startup
    # end

    # startup_names = @search_results.hits.map{ |hit| hit.stored(:name) }

    # logger.info startup_names.inspect

    render :json =>  startups.map{|s| s.name }
  end

end

  
