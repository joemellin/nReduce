class RelationshipsController < ApplicationController
  before_filter :login_required
  before_filter :startup_required

  def create
    connect_with = Startup.find(params[:startup_id])
    relationship = Relationship.start_between(@startup, connect_with)
    if relationship.pending?
      flash[:notice] = "Your connection has been requested with #{connect_with.name}."
    elsif relationship.approved?
      flash[:notice] = "You are connected to #{connect_with.name}."
    elsif relationship.rejected?
      flash[:error] = "Sorry but #{connect_with.name} has already denied your connection."
    end
    redirect_to root_path
  end

  def approve
    relationship = Relationship.find(params[:id])
    if relationship.approve!
      flash[:notice] = "You are now connected to #{relationship.startup.name}."
    else
      flash[:alert] = "Sorry but the relationship couldn't be approved at this time."
    end
    redirect_to root_path
  end

  def reject
    relationship = Relationship.find(params[:id])
    if relationship.reject!
      flash[:notice] = "You have rejected a connection with #{relationship.startup.name}."
    else
      flash[:alert] = "Sorry but the relationship couldn't be rejected at this time."
    end
    redirect_to root_path
  end
end
