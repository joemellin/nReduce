class MeetingController < ApplicationController
  before_filter :login_required

  def index
    @current_meeting = @current_user.meeting
    @meetings = Meeting.all
  end

  def show
    @meeting = Meeting.find(params[:id])
  end

  def message_attendees
    @meeting = Meeting.find(params[:id])
  end
end
