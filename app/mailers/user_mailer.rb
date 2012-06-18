class UserMailer < ActionMailer::Base
  default from: "notifications@nreduce.com"

  def new_checkin(notification)
    setup_email
    @checkin = notification.checkin
    @user = notification.user
    mail(:to => user.email, :subject => "#{@checkin.startup.name} has posted their check-in for this week")
  end

  def relationship_request(notification)
    setup_email
    @relationship = notification.attachable
    @requesting_startup = @relationship.startup
    @user = notification.user
    mail(:to => @user.email, :subject => "#{@requesting_startup.name} wants to connect with you")
  end

  def relationship_approved(notification)
    setup_email
    @relationship = notification.attachable
    @connected_with = @relationship.connected_with
    @user = notification.user
    mail(:to => @user.email, :subject => "#{@connected_with.name} approved your connection request")
  end

  def new_comment(notification)
    setup_email
    @comment = notification.attachable
    @checkin = @comment.checkin
    @user = notification.user
    mail(:to => @user.email, :subject => "#{@comment.user.name} commented on your check-in")
  end


  # Remind all attendees to come to local meeting
  def meeting_reminder(user, meeting, message, subject = nil)
    setup_email
    subject ||= "Join us at #{meeting.location_name} meeting at #{meeting.venue_name}"
    @meeting = meeting
    @message = message
    mail(:to => user.email, :subject => subject)
  end

  def before_checkin_reminder(user)
    setup_email
    @user = user
    mail(:to => user.email, :subject => "What's your focus this week?")
  end

  def after_checkin_reminder(user)
    setup_email
    @user = user
    mail(:to => user.email, :subject => "What did you accomplish this week?")
  end

  protected

  def setup_email
    attachments.inline['emailheader.jpg'] = File.read(File.join(Rails.root,'public', 'images', 'emailheader.jpg'))
  end
end
