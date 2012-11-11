class SmsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  
  def receive
    message_body = params["Body"]
    from_number = params["From"]

    Call.respond_to_message(from_number, message_body)
    render :nothing => true
  end
end
