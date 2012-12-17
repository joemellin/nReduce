class RelationshipsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup, :only => [:index, :add_teams]
  load_and_authorize_resource :except => [:index, :add_teams, :skip_team]

  def index
    no_startups = false

    if current_user.mentor?
      @entity = current_user
    elsif @startup
      @entity = @startup
    end
    unless can? :read, Relationship.new(:entity => @entity)
      redirect_to current_user
      return
    end

    startup_ids = @entity.connected_to_ids('Startup')

    # Add nreduce to list if they don't have any startups
    if !current_user.entrepreneur? and startup_ids.blank?
      no_startups = true
    end
      
    # Add nReduce for everyone to see
    startup_ids << Startup.nreduce_id

    # Load startups
    @startups = Startup.where(:id => startup_ids).all

    if current_user.mentor?
      @checkins_by_startup = Checkin.current_checkin_for_startups(@startups)
    else
      @checkins_by_startup = Checkin.current_checkin_for_startups(@startups + [@startup])
    end

    # Sort by startups who have the most recent completed checkins first
    long_ago = Time.now - 100.years
    @startups.sort! do |a,b|
      a_time, b_time = long_ago, long_ago
      if !@checkins_by_startup[a.id].blank?
        a_time = @checkins_by_startup[a.id].completed_at if @checkins_by_startup[a.id].completed?
      end
      if !@checkins_by_startup[b.id].blank?
        b_time = @checkins_by_startup[b.id].completed_at if @checkins_by_startup[b.id].completed?
      end
      a_time <=> b_time
    end
    # Sort by reverse chrono order
    @startups.reverse!

    @commented_on_checkin_ids = current_user.commented_on_checkin_ids

    #@checkin_data = Checkin.participant_data_for_checkins(@checkins_by_startup.values.map{|c| c.id })

    @show_mentor_message = true if current_user.roles?(:nreduce_mentor) && no_startups == true

    @checkin_window = Checkin.in_time_window?(@startup ? @startup.checkin_offset : Checkin.default_offset) ? true : false

    store_users_by_ids(User.where(:startup_id => @startups.map{|s| s.id }))
    store_users_by_startup_id(@users_by_id.map{|id, user| user })

    if session[:checkin_completed] == true && !@startup.blank?
      @checkin_completed = true
      @number_of_consecutive_checkins = @startup.number_of_consecutive_checkins
      session[:checkin_completed] = false
    end

    if current_user.entrepreneur?
      requests = Request.ordered.includes(:responses).all
      @users_requests = requests.select{|r| r.startup_id == current_user.startup_id }
      @users_requests.sort!{|a,b| a_score = !a.closed? ? 1 : 0 <=> !b.closed? ? 1 : 0 }.reverse!
      @available_requests = requests.select{|r| r.startup_id != current_user.startup_id && !r.closed? }
      @authenticated_for_twitter = current_user.authenticated_for?('twitter')
      if !current_user.seen_help_exchange_message?
        @earn_message = true
        current_user.setup << :help_exchange
        current_user.save
      elsif params[:earn].present?
        @earn_message = true
      end
    end

    # just successfully completed request
    if session[:response_success_id].present?
      @response = Response.find(session[:response_success_id])
      session[:response_success_id] = nil
    end
  end

  def add_teams
    authorize! :add_teams, Relationship
    suggested = false
    if current_user.mentor? || current_user.investor?
      @entity = current_user
      @relationship = @entity.pending_relationships.last
      if @relationship.blank?
        flash[:notice] = "Those are all the teams that have requested to connect with you."
        redirect_to '/'
        return
      end
      @review_startup = @relationship.entity
    elsif @startup
      @entity = @startup

      # Otherwise load suggested startup
      session[:suggested_startup_ids] = @startup.generate_suggested_connections.map{|s| s.id } if session[:suggested_startup_ids].blank?

      next_id = session[:suggested_startup_ids].first if session[:suggested_startup_ids].present?

      # If there are none left to suggest
      if next_id.blank?
        flash[:notice] = "Those are all the teams you can connect to - check back next week for more teams."
        redirect_to '/'
        return
      end

      @review_startup = Startup.find(next_id)
      @relationship = Relationship.start_between(@startup, @review_startup, :startup_startup, false, true)
      suggested = true

      @startups_in_common = Relationship.startups_in_common(@review_startup, @startup)
      @num_checkins = @review_startup.checkins.count
      @num_awesomes = @review_startup.awesomes.count
      if suggested == true
        if @startup.num_active_startups >= Startup::NUM_ACTIVE_REQUIRED
          @pct_complete = 100
        else
          @num_invites_sent = @startup.initiated_relationships.pending.where(['pending_at > ?', Time.now - 1.week]).count
          @pct_complete = ((@num_invites_sent.to_f / Startup::NUM_ACTIVE_REQUIRED.to_f) * 100).round
          @num_left_to_invite = Startup::NUM_ACTIVE_REQUIRED - @num_invites_sent
        end
        @ua = {:action => UserAction.id_for('relationships_suggest'), :data => {:id => @review_startup.id}}
      else
        @ua = {:action => UserAction.id_for('relationships_show'), :data => {:id => @review_startup.id}} 
      end
    end
    # Suggested, pending relationships and invited startups
    #@suggested_startups = @startup.suggested_startups(10) unless @startup.blank?
    #@pending_relationships = @entity.pending_relationships
    #@invited_startups = current_user.sent_invites.to_startups.not_accepted.ordered

    @modal = true
  end

  def skip_team
    session[:suggested_startup_ids].delete(params[:startup_id].to_i) if params[:startup_id].present?
    flash[:notice] = "You have seen all of your suggested teams - you can continue to check out any that you didn't connect with." if session[:suggested_startup_ids].blank?
    redirect_to :action => :add_teams
  end

  def create
    @relationship.from_user_id = current_user.id
    if !@relationship.save
      flash[:alert] = @relationship.errors.full_messages.join(', ') + '.'
    elsif @relationship.pending?
      flash[:notice] = "Your connection has been requested with #{@relationship.connected_with.name}."
    elsif @relationship.approved?
      flash[:notice] = "You are already connected to #{@relationship.connected_with.name}."
    elsif @relationship.rejected?
      flash[:alert] = "Sorry, but #{@relationship.connected_with.name} has ignored your connection request."
    end
    respond_to do |format|
      format.html { redirect_to add_teams_relationships_path }
      format.js { render :action => 'update_modal' }
    end
  end

  def approve
    @relationship.message = params[:relationship][:message] if !params[:relationship].blank? and !params[:relationship][:message].blank?
    suggested = true if @relationship.suggested?
    if @relationship.approve!
      # Update rating to say investor connected if so
      unless params[:rating_id].blank?
        r = Rating.find(params[:rating_id])
        r.update_attribute('connected', true) if !r.startup_relationship.blank? && (r.startup_relationship == @relationship)
      end
      if suggested
        flash[:notice] = "Your request has been sent to #{@relationship.connected_with.name}."
      else
        flash[:notice] = "You are now connected to #{@relationship.entity.name}."
      end
    else
      flash[:alert] = "Sorry but the relationship couldn't be approved at this time."
    end
    if request.xhr?
      respond_to do |format|
        format.js { render :action => 'update_modal' }
      end
    else
      redirect_to '/'
    end
  end

  def reject
    prev_status_pending = @relationship.pending?
    prev_status_suggested = @relationship.suggested?
    if @relationship.reject_or_pass!
      removed = @relationship.entity if (@relationship.connected_with == current_user) or (!current_user.startup.blank? and (@relationship.connected_with == current_user.startup))
      removed ||= @relationship.connected_with
      # Update rating to say startup didn't connect
      unless params[:rating_id].blank?
        r = Rating.find(params[:rating_id])
        r.update_attribute('connected', false) if !r.startup_relationship.blank? && (r.startup_relationship == @relationship)
      end
      if prev_status_pending
        flash[:notice] = "You have ignored the connection request from #{removed.name}."
      elsif prev_status_suggested
        #flash[:notice] = "You have passed on that suggested connection."
      else
        flash[:notice] = "You have removed #{removed.name} from your group."
      end
    else
      flash[:alert] = "Sorry but the relationship couldn't be removed at this time."
    end
    # Save user action as removed unless it was a rejection
    @ua = {:action => UserAction.id_for('relationships_remove')} if @relationship.removed?
    if request.xhr?
      respond_to do |format|
        format.js { render :action => 'update_modal' }
      end
    else
      redirect_to '/'
    end
  end

  def mark_all_as_seen
    entity = current_user.entrepreneur? ? current_user.startup : current_user
    entity.pending_relationships.each{|r| r.mark_as_seen!(current_user.id) unless r.seen_by?(current_user.id) }
    render :nothing => true
  end
end
