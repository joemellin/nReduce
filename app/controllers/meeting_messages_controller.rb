class MeetingMessagesController < ApplicationController
  before_filter :login_required
  load_and_authorize_resource :meeting
  load_and_authorize_resource :through => :meeting

  def index
  end

  def new
    @meeting_messages = @meeting.meeting_messages.ordered.limit(5)
    if @meeting.attendees.count == 0
      flash[:alert] = "There aren't any attendees for this meeting, so you can't send a message."
      redirect_to @meeting
      return
    end
    render :action => :edit
  end

  def create
    @meeting_message.user = current_user
    @meeting_message.meeting = @meeting
    if @meeting_message.save
      flash[:notice] = "Your message has been sent to all the attendees."
      redirect_to @meeting
    else
      @meeting_messages = @meeting.meeting_messages.ordered.limit(5)
      render :action => :edit
    end
  end
end
