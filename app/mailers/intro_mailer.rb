class IntroMailer < ActionMailer::Base
  default :from => Settings.default_from_email
  default reply_to: Settings.default_reply_to_email

  def startup(user)
    @user = user
    @confirm_url = "http://#{Settings.email_host}/confirm/#{@user.token}"

    mail({
      :to => user.email,
      :subject => "[nReduce S12] We need a few details about your startup.",
    })
  end

  def rsvp(user)
    @user = user

    @confirm_url = "http://#{Settings.email_host}/rsvp/#{@user.token}"
    @register_url = "http://#{Settings.email_host}/startups/new"

    mail({
      :to => user.email,
      :subject => "[nReduce S12] RSVP for the first dinner",
    })
  end
end