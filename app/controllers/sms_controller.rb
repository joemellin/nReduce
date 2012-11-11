class SmsController < ApplicationController
  def receive
    message_body = params["Body"]
    from_number = params["From"]

    Call.respond_to_message(from_number, message_body)
  end
end
