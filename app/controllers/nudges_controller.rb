class NudgesController < ApplicationController
  before_filter :login_required
  before_filter :load_requested_or_users_startup
  load_and_authorize_resource

  # Mark nudge as being seen and redirect to user's current checkin
  def show
    if !@startup.blank? and @nudge.startup_id == @startup.id
      @nudge.seen_at = Time.now
      @nudge.save
      flash[:notice] = "#{@nudge.from.name} nudged you to finish your check-in!"
      redirect_to new_checkin_path
    else
      redirect_to relationships_path
    end
  end

  def create
    # odd bug, but when posted with an invite id, a startup is assigned in can can's load_and_authorize_resource
    @nudge.startup = nil unless params[:nudge] and !params[:nudge][:startup_id].blank?
    @nudge.from = current_user
    if @nudge.save
      flash[:notice] = "#{@nudge.to_name} has been nudged with an email!"
    else
      flash[:alert] = "Oops we couldn't nudge them. Try again in a bit..."
    end
    redirect_to relationships_path
  end

  def nudge_all_inactive
    nudges = []
    @startup.inactive_startups.each do |s|
      nudges << Nudge.create(:from_id => current_user.id, :startup_id => s.id)
    end
    flash[:notice] = "#{nudges.size} teams have been nudged!"
    redirect_to relationships_path
  end
end
