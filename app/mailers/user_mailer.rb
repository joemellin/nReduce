class UserMailer < ActionMailer::Base
  default from: Settings.default_from_email
  default reply_to: Settings.default_reply_to_email

  def response_completed(notification)
    @response = notification.attachable
    @to = notification.user
    mail(:to => @to.email, :subject => "#{@response.user.name} completed your help request")
  end

  def new_message(message, user)
    @message = message
    @user = user
    mail(:to => @user.email, :subject => "New message from #{@message.from.name}")
  end

  def checkin_now(user)
    mail(:to => user.email, :subject => "Stop. Drop. Checkin!")
  end

  def new_team_joined(notification)
    @startup = notification.attachable
    @to = notification.user
    mail(:to => @to.email, :subject => "Team #{@startup.name} joined nReduce!")
  end

  def join_next_week(notification)
    @weekly_class = notification.attachable
    @user = notification.user
    @stats = @weekly_class.stats_for_completed_startups
    mail(:to => @user.email, :subject => "Come join us")
  end

  def new_checkin(notification)
    @checkin = notification.attachable
    @user = notification.user
    mail(:to => @user.email, :subject => "#{@checkin.startup.name} has posted their check-in for this week")
  end

  def new_like(notification)
    @post = notification.attachable.awsm
    @poster = @post.user
    @from = notification.user
    mail(:to => @poster.email, :subject => "#{@from.name} likes your post")
  end

  def relationship_request(notification)
    @user = notification.user
    @relationship = notification.attachable
    @requesting_entity = @relationship.entity
    @connected_with = @relationship.connected_with
    return false if @user.blank? or @requesting_entity.blank? or @connected_with.blank? or @relationship.blank?
    if @requesting_entity.is_a?(User) and @requesting_entity.roles?(:mentor)
      subject = "#{@requesting_entity.name} wants to be your mentor"
    else
      subject = "#{@requesting_entity.name} wants to connect with you"
    end
    params = {:to => @user.email, :subject => subject}
    params[:bcc] = 'joe@nReduce.com' if @connected_with.is_a?(User) and @connected_with.roles?(:mentor)
    mail(params)
  end

  def relationship_approved(notification)
    @relationship = notification.attachable
    @connected_with = @relationship.connected_with
    @user = notification.user
    mail(:to => @user.email, :subject => "#{@connected_with.name} approved your connection request")
  end

   # We introduced the two teams when one joined
  def relationship_introduced(notification)
    @relationship = notification.attachable
    @connected_with = @relationship.connected_with
    @user = notification.user
    mail(:to => @user.email, :subject => "We've introduced you to #{@connected_with.name}")
  end

  def mentorship_approved(notification)
    @relationship = notification.attachable
    @connected_with = @relationship.connected_with
    @user = notification.user
    mail(:to => @user.email, :subject => "You have a new team!")
  end

  def investor_approved(notification)
    @relationship = notification.attachable
    @connected_with = @relationship.connected_with
    @user = notification.user
    mail(:to => @user.email, :subject => "You have a new team!")
  end

  def new_comment_for_checkin(notification)
    @comment = notification.attachable
    @checkin = @comment.checkin
    @user = notification.user
    @owner = @user.startup_id == @checkin.startup_id
    if @owner
      subject = "#{@comment.user.name} commented on your check-in" 
    else
      subject = "#{@comment.user.name} replied to your comment"
    end
    mail(:to => @user.email, :subject => subject)
  end

  def new_comment_for_post(notification)
    @comment = notification.attachable
    @original_post = @comment.root
    @user = notification.user
    @owner = @comment.root.user_id == @user.id
    if @owner
      subject = "#{@comment.user.name} commented on your post"
    else
      subject = "#{@comment.user.name} replied to your #{@comment.original_post? ? 'post' : 'comment'}"
    end
    mail(:to => @user.email, :subject => subject)
  end

  # Remind all attendees to come to local meeting
  def meeting_reminder(user, meeting, message, subject = nil)
    subject ||= "Join us at #{meeting.location_name} meeting at #{meeting.venue_name}"
    @meeting = meeting
    @message = message
    mail(:to => user.email, :subject => subject)
  end

  def before_checkin_reminder(user)
    @user = user
    mail(:to => user.email, :subject => "What's your focus this week?")
  end

  def after_checkin_reminder(user)
    @user = user
    mail(:to => user.email, :subject => "What did you accomplish this week?")
  end

  def invite_team_member(invite)
    @invite = invite
    mail(:to => invite.email, :subject => "#{invite.startup.name} wants to add you to their team on nReduce", :reply_to => invite.from.email)
  end

  def invite_mentor(invite)
    @invite = invite
    mail(:to => @invite.email, :subject => "#{@invite.from.name} invited you to nReduce", :reply_to => invite.from.email)
  end

  def invite_investor(invite)
    @invite = invite
    mail(:to => @invite.email, :subject => "#{@invite.from.name} invited you to nReduce", :reply_to => invite.from.email)
  end

  def invite_startup(invite)
    @invite = invite
    mail(:to => @invite.email, :subject => "#{@invite.from.name} invited you to join nReduce", :reply_to => invite.from.email)
  end

  # Nudges startup to do check-in
  def new_nudge(notification)
    @nudge = notification.attachable
    @from = @nudge.from
    @to = notification.user
    @to_startup = @nudge.startup
    mail(:to => @to.email, :subject => "#{@from.name} nudged you to complete your check-in", :reply_to => @from.email)
  end

  def nudge_for_invite(nudge)
    @invite = nudge.invite
    @from = nudge.from
    mail(:to => @invite.email, :subject => "#{@from.name} nudged you to join nReduce")
  end

  def community_status(user)
    @user = user
    mail(:to => @user.email, :subject => "Your nReduce community status")
  end
end
