class SmsController < ApplicationController
  def receive
    message_body = params["Body"]
    from_number = params["From"]

    @client = Twilio::REST::Client.new(Settings.twilio.sid, Settings.twilio.token)
    @account = @client.account
    @account.sms.messages.create(:from => '+14159341234', :to => '+16105557069', :body => 'Hey there!')
  end
end
