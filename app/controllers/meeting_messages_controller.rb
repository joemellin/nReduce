class MeetingMessagesController < ApplicationController
  before_filter :login_required
  before_filter :meeting_organizer_required

  def index
    @meeting_messages = @meeting.meeting_messages
  end

  def new
    @meeting_message = MeetingMessage.new(:meeting_id => @meeting.id)
  end

  def create
    @meeting_message = MeetingMessage.new(params[:meeting_message])
    @meeting_message.user = current_user
    @meeting_message.meeting = @meeting
    if @meeting_message.save
      flash[:notice] = "The attendees have been messaged"
      redirect_to @meeting
    else
      render :action => :edit
    end
  end
end
