class CallsController < ApplicationController
  before_filter :load_call

  # Generic callback handler
  def receive
    # Looks like we hit an answering machine
    if params['AnsweredBy'].present? && params['AnsweredBy'] == 'machine'
      # Hang up and call again if first attempt
      # Otherwise notify other caller that there was no answer
      handle_failed_call
    end
  end

  # Will say the message and then hang up
  def other_party_unavailable
    @say = "Sorry but the #{@caller_role == :from ? 'founder' : 'mentor'} could not make the call."
    # Update state of receiver to say they have received message and call is considered completed for them
    @call.send("#{@opposite_role}_state", :completed)
  end

  def connected
    if @caller_role == :to
      # Connect both parties together
      @phone = @call.from.phone
      @call.update_attribute(:to_state, :connected)
      render :action => :dial
    elsif @caller_role == :from
      @call.update_attribute(:from_state, :connected)
      render :nothing => true
    end
  end

  # Call has finished for one of the callers
  def completed
    if @caller_role == :from
      @call.from_state = :completed
    elsif @caller_role == :to
      @call.to_state = :completed
    end
    @call.save
    render :nothing => true
  end

  def failed
    handle_failed_call
  end

  protected

  def handle_failed_call
    state = @call.send("#{@caller_role}_state".to_sym).first
    if state == :first_attempt
      @call.send("#{@caller_role}_state".to_sym, :second_attempt)
      @call.perform_call_to_user(:from)
      render :nothing => true
    elsif state == :second_attempt
      # Update state
      @call.send("#{@caller_role}_state".to_sym, :failed)
      
      # Notify other caller that it has failed
      @twilio_call = TwilioClient.account.calls.get(@caller_role == :from ? @call.to_sid : @call.from_sid)
      @twilio_call.redirect_to(url)

      render :nothing => true
    end
  end

  def load_call
    @from_number = params["From"]
    @call_sid = params["CallSid"]
    @call = Call.get_call_for_sid(@call_sid) unless @call_sid.blank?
    if @call.blank?
      render :nothing => true
      return false
    end
    @caller_role = @call.caller_role_from_number(@from_number)
    @opposite_role = @caller_role == :from ? :to : :from
    true
  end
end
