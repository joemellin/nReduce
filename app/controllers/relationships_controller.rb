class RelationshipsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :load_requested_or_users_startup, :only => :index
  load_and_authorize_resource :except => :index

  def index
    if current_user.mentor?
      @entity = current_user
    elsif @startup
      @entity = @startup
      @current_checkin = @entity.current_checkin
    end
    unless can? :read, Relationship.new(:entity => @entity)
      redirect_to current_user
      return
    end
    @startups = @entity.connected_to
    @pending_relationships = @entity.pending_relationships
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
      format.js
    end
  end

  def approve
    if @relationship.approve!
      flash[:notice] = "You are now connected to #{@relationship.entity.name}."
    else
      flash[:alert] = "Sorry but the relationship couldn't be approved at this time."
    end
    redirect_to relationships_path
  end

  def reject
    prev_status_pending = @relationship.pending?
    if @relationship.reject!
      removed = @relationship.entity if (@relationship.connected_with == current_user) or (!current_user.startup.blank? and (@relationship.connected_with == current_user.startup))
      removed ||= @relationship.connected_with
      if prev_status_pending
        flash[:notice] = "You have ignored the connection request from #{removed.name}."
      else
        flash[:notice] = "You have removed #{removed.name} from your group."
      end
    else
      flash[:alert] = "Sorry but the relationship couldn't be removed at this time."
    end
    redirect_to relationships_path
  end
end
