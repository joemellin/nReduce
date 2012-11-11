class TwilioClient
  @@twilio_account = nil

  def self.account
    return @@twilio_account unless @@twilio_account.blank?
    @client = Twilio::REST::Client.new(Settings.apis.twilio.sid, Settings.apis.twilio.token)
    @@twilio_account = @client.account
  end
end