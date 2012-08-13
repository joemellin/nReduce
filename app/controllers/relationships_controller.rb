class RelationshipsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup, :only => [:index, :add_teams]
  load_and_authorize_resource :except => [:index, :add_teams]

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
    @startups = @entity.connected_to
        # Add nreduce to list if they don't have any startups
    if !current_user.entrepreneur? and @startups.blank?
      @startups = Startup.where(:id => Startup.nreduce_id)
      no_startups = true
    end 

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
        if @checkins_by_startup[a.id].completed?
          a_time = @checkins_by_startup[a.id].completed_at
        elsif @checkins_by_startup[a.id].submitted?
          a_time = @checkins_by_startup[a.id].submitted_at
        end
      end
      if !@checkins_by_startup[b.id].blank?
        if @checkins_by_startup[b.id].completed?
          b_time = @checkins_by_startup[b.id].completed_at
        elsif @checkins_by_startup[b.id].submitted?
          b_time = @checkins_by_startup[b.id].submitted_at
        end
      end
      a_time <=> b_time
    end
    # Add user's startup (if not mentor) to the beginning, and then sort by reverse chrono order
    if current_user.mentor?
      @startups.reverse!
    else
      @startups = [@startup] + @startups.reverse
    end
    @commented_on_checkin_ids = current_user.commented_on_checkin_ids

    @num_blank_spots = current_user.mentor? ? 4 : 8

    @show_mentor_message = true if current_user.roles?(:nreduce_mentor) && no_startups == true
  end

  def add_teams
    if current_user.mentor?
      @entity = current_user
    elsif @startup
      @entity = @startup
    end
     # Suggested, pending relationships and invited startups
    @suggested_startups = @startup.suggested_startups(4) unless @startup.blank?
    @pending_relationships = @entity.pending_relationships
    @invited_startups = current_user.sent_invites.to_startups.not_accepted.ordered
    @modal = true
  end

  def create
    if !@relationship.save
      flash[:alert] = @relationship.errors.full_messages.join(', ') + '.'
    elsif @relationship.pending?
      flash[:notice] = "Your connection has been requested with #{@relationship.connected_with.name}."
    elsif @relationship.approved?
      flash[:notice] = "You are already connected to #{@relationship.connected_with.name}."
    elsif @relationship.rejected?
      flash[:alert] = "Sorry, but #{@relationship.connected_with.name} has ignored your connection request."
    end
    logger.info flash.inspect
    respond_to do |format|
      format.html { redirect_to '/' }
      format.js { render :action => 'update_modal' }
    end
  end

  def approve
    @relationship.message = params[:relationship][:message] if !params[:relationship].blank? and !params[:relationship][:message].blank?
    suggested = true if @relationship.suggested?
    if @relationship.approve!
      if suggested
        flash[:notice] = "Your connection has been requested with #{@relationship.connected_with.name}"
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
      redirect_to relationships_path
    end
  end

  def reject
    prev_status_pending = @relationship.pending?
    prev_status_suggested = @relationship.suggested?
    if @relationship.reject_or_pass!
      removed = @relationship.entity if (@relationship.connected_with == current_user) or (!current_user.startup.blank? and (@relationship.connected_with == current_user.startup))
      removed ||= @relationship.connected_with
      if prev_status_pending
        flash[:notice] = "You have ignored the connection request from #{removed.name}."
      elsif prev_status_suggested
        flash[:notice] = "You have passed on that suggested connection."
      else
        flash[:notice] = "You have removed #{removed.name} from your group."
      end
    else
      flash[:alert] = "Sorry but the relationship couldn't be removed at this time."
    end
    redirect_to relationships_path
  end
end
