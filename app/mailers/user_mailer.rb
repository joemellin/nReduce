class UserMailer < ActionMailer::Base
  default from: "notifications@nreduce.com"

  def new_checkin(notification)
    @user = user
    mail(:to => user.email, :subject => "[nReduce S12] RSVP for the first dinner")
  end

  def relationship_request(notification)

  end

  def relationship_approved(notification)

  end

  def meeting_reminder(user, meeting, message, subject = nil)
    subject ||= "Join us at #{meeting.location_name} meeting at #{meeting.venue_name}"
    @meeting = meeting
    @message = message
    mail(:to => user.email, :subject => subject)
  end

  def new_comment(notification)

  end
end
