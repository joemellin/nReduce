class MeetingsController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource

  def index
    @current_meeting = current_user.meeting
    @meetings = @meetings.order(:location_name)
  end

  def show
    if can? :edit, @meeting
      @attendees = @meeting.attendees.order(:name).includes(:startup)
      @attendees = @attendees.sort{|a,b| (a.startup.blank? ? '' : a.startup.name) <=> (b.startup.blank? ? '' : b.startup.name) }.reverse
      @meeting_messages = @meeting.meeting_messages.ordered.limit(5)
      @can_edit = true
    end
  end

  def edit
  end

  def update
    if @meeting.update_attributes(params[:meeting])
      flash[:notice] = "Meeting has been updated."
      redirect_to @meeting
    else
      render :action => :edit
    end
  end
end
