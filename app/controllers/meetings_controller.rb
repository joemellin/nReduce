class MeetingsController < ApplicationController
  before_filter :login_required
  before_filter :meeting_organizer_required, :only => [:edit, :update]

  def index
    @current_meeting = current_user.meeting
    @meetings = Meeting.order(:location_name)
  end

  def show
    @meeting = Meeting.find(params[:id])
    @can_edit = user_signed_in? and (current_user.admin? or (current_user.id == @meeting.organizer_id))
    if @can_edit
      @meeting_messages = @meeting.meeting_messages.ordered.limit(5)
    end
  end

  def edit
    @meeting = Meeting.find(params[:id])
  end

  def update
    @meeting = Meeting.find(params[:id])
    if @meeting.update_attributes(params[:meeting])
      flash[:notice] = "Meeting has been updated."
      redirect_to @meeting
    else
      render :action => :edit
    end
  end
end
