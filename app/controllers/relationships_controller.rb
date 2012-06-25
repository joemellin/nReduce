class RelationshipsController < ApplicationController
  around_filter :record_user_action
  before_filter :login_required
  before_filter :current_startup_required

  def index
    @startups = @current_startup.connected_to
    @pending_relationships = @current_startup.pending_relationships
    @current_checkin = @current_startup.current_checkin
    @checkins_by_startup = Checkin.current_checkin_for_startups(@startups + [@current_startup])
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
    # Add user's startup to the beginning, and then sort by reverse chrono order
    @startups = [@current_startup] + @startups.reverse
  end

  def create
    connect_with = Startup.find(params[:startup_id])
    @relationship = Relationship.start_between(@current_startup, connect_with)
    if @relationship.blank? and connect_with.id == @current_startup.id
      flash[:alert] = "You aren't allowed to connect with yourself, silly!"
    elsif @relationship.pending?
      flash[:notice] = "Your connection has been requested with #{connect_with.name}."
    elsif @relationship.approved?
      flash[:notice] = "You are already connected to #{connect_with.name}."
    elsif @relationship.rejected?
      flash[:alert] = "Sorry, but #{connect_with.name} has ignored your connection request."
    end
    respond_to do |format|
      format.html { redirect_to search_startups_path }
      format.js
    end
  end

  def approve
    relationship = Relationship.find(params[:id])
    if relationship.approve!
      flash[:notice] = "You are now connected to #{relationship.startup.name}."
    else
      flash[:alert] = "Sorry but the relationship couldn't be approved at this time."
    end
    redirect_to relationships_path
  end

  def reject
    relationship = Relationship.find(params[:id])
    if relationship.reject!
      flash[:notice] = "You have rejected a connection with #{relationship.startup.name}."
    else
      flash[:alert] = "Sorry but the relationship couldn't be rejected at this time."
    end
    redirect_to relationships_path
  end
end
