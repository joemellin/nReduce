class TwilioClient
  @@twilio_account = nil

  def self.account
    return @@twilio_account unless @@twilio_account.blank?
    @client = Twilio::REST::Client.new(Settings.twilio.sid, Settings.twilio.token)
    @@twilio_account = @client.account
  end
end