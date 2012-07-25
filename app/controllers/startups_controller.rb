class StartupsController < ApplicationController
  around_filter :record_user_action, :except => [:onboard_next, :stats]
  before_filter :login_required
  before_filter :load_requested_or_users_startup, :except => [:index, :invite, :stats]
  load_and_authorize_resource :except => [:index, :stats, :invite]
  before_filter :redirect_if_no_startup, :except => [:index, :invite]

  def index
    redirect_to :action => :search
  end

  def new
    redirect_to :action => :edit unless @startup.new_record?
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
        else
          flash[:alert] = "#{@invite.errors.full_messages.join('. ')}."
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
    @checkins = @startup.checkins.ordered
    if current_user.entrepreneur?
      @entity = current_user.startup unless current_user.startup.blank?
    else
      @entity = current_user
    end
    if params[:suggested] # we need to look for a relationship in the opposite direction if suggested
      @relationship = Relationship.between(@entity, @startup)
    else
      @relationship = Relationship.between(@startup, @entity)
    end
  end

  def search
    if !params[:search].blank?
      # sanitize search params
      params[:search].select{|k,v| [:name, :meeting_id, :industries].include?(k) }

      # save in session for pagination
      @search = session[:search] = params[:search]
    elsif !params[:page].blank?
      @search = session[:search]
    end

    @search ||= {}
    @search[:page] = 1 # Force one page
    @search[:per_page] = 20
    @search[:sort] ||= 'rating'

    # Have to pass context for block or else you can't access @search instance variable
    @search_results = Startup.search do |s|
      s.fulltext @search[:name] unless @search[:name].blank?
      s.with :onboarding_step, Startup.num_onboarding_steps
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

    # # Establish basic query to find public startups
    # @startups = Startup.is_public.where(:onboarding_step => Startup.num_onboarding_steps).order('startups.name').includes(:team_members).paginate(:page => @search[:page], :per_page => 10)

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
    @ua = {:data => @search}
    @meetings_by_id = Meeting.location_name_by_id
    #@tags_by_startup_id = Startup.tags_by_startup_id(@startups)

    if current_user.mentor?
      @entity = current_user
    elsif !current_user.startup.blank?
      @entity = current_user.startup
    end
  end

  #
  # Actions for user's startup
  #

  def edit
    @profile_elements = @startup.profile_elements
    @profile_completeness_percent = (@startup.profile_completeness_percent * 100).round
  end

  def update
    @startup.attributes = params[:startup]
    if @startup.save
      #flash[:notice] = "Startup information has been saved. Thanks!"
      redirect_to '/startup'
    else
      render :edit
    end
  end

  def invite_team_members
    if request.post?
      @startup.invited_team_members!
      redirect_to '/'
      return
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
end