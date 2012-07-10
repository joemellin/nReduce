class UserMailer < ActionMailer::Base
  default from: Settings.default_from_email
  default reply_to: Settings.default_reply_to_email

  def new_checkin(notification)
    setup_email
    @checkin = notification.attachable
    @user = notification.user
    @current_checkin = @user.startup.current_checkin || Checkin.new
    mail(:to => @user.email, :subject => "#{@checkin.startup.name} has posted their check-in for this week")
  end

  def relationship_request(notification)
    setup_email
    @relationship = notification.attachable
    @requesting_entity = @relationship.entity
    @connected_with = @relationship.connected_with
    @user = notification.user
    if @requesting_entity.roles?(:mentor)
      subject = "#{@requesting_entity.name} wants to be your mentor"
    else
      subject = "#{@requesting_entity.name} wants to connect with you"
    end
    mail(:to => @user.email, :subject => subject)
  end

  def relationship_approved(notification)
    setup_email
    @relationship = notification.attachable
    @connected_with = @relationship.connected_with
    @user = notification.user
    mail(:to => @user.email, :subject => "#{@connected_with.name} approved your connection request")
  end

  def mentorship_approved(notification)
    setup_email
    @relationship = notification.attachable
    @connected_with = @relationship.connected_with
    @user = notification.user
    mail(:to => @user.email, :subject => "You have a new team!")
  end

  def new_comment(notification)
    setup_email
    @comment = notification.attachable
    @checkin = @comment.checkin
    @user = notification.user
    @owner = @user.startup_id == @checkin.startup_id
    subject = @owner ? "#{@comment.user.name} commented on your check-in" : "#{@comment.user.name} replied to your comment"
    mail(:to => @user.email, :subject => subject)
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

  def invite_team_member(invite)
    setup_email
    @invite = invite
    mail(:to => invite.email, :subject => "#{invite.startup.name} wants to add you to their team on nReduce")
  end

  def invite_mentor(invite)
    setup_email
    @invite = invite
    mail(:to => @invite.email, :subject => "Welcome to nReduce")
  end

  # Nudges startup to do check-in
  def new_nudge(notification)
    setup_email
    @nudge = notification.attachable
    @from = @nudge.from
    @to = notification.user
    @to_startup = @nudge.startup
    mail(:to => @to.email, :subject => "#{@from.name} nudged you to complete your check-in")
  end

  def community_status(user)
    setup_email
    @user = user
    mail(:to => @user.email, :subject => "Your nReduce community status")
  end

  protected

  def setup_email
    attachments.inline['emailheader.jpg'] = File.read(File.join(Rails.root,'public', 'images', 'emailheader.jpg'))
  end
end
