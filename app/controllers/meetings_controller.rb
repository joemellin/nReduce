class MeetingsController < ApplicationController
  before_filter :login_required
  before_filter :meeting_organizer_required, :only => [:edit, :update]

  def index
    @current_meeting = current_user.meeting
    @meetings = Meeting.order(:location_name)
  end

  def show
    @meeting = Meeting.find(params[:id])
    @can_edit = can_edit_meeting?(@meeting)
    if @can_edit
      @meeting_messages = @meeting.meeting_messages.ordered.limit(5)
      @attendees = @meeting.attendees.order(:name).includes(:startup)
    end
  end

  def edit
    @meeting = Meeting.find(params[:id])
    redirect_to(@meeting) && return unless can_edit_meeting?(@meeting)
  end

  def update
    @meeting = Meeting.find(params[:id])
    redirect_to(@meeting) && return unless can_edit_meeting?(@meeting)
    if @meeting.update_attributes(params[:meeting])
      flash[:notice] = "Meeting has been updated."
      redirect_to @meeting
    else
      render :action => :edit
    end
  end

  protected

  def can_edit_meeting?(meeting)
    user_signed_in? and (current_user.admin? or (current_user.id == meeting.organizer_id))
  end
end
