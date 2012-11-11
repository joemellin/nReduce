class CallsController < ApplicationController
  def receive

  end

  def start_conference
    from_number = params["From"]
    call_sid = params["CallSid"]
    @call = Call.get_call_for_sid(call_sid)
    render :nothing => true if @call.blank?
  end
end
