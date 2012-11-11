class CallsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  before_filter :load_call

  # Generic callback handler
  def receive
    # Looks like we hit an answering machine
    if params['AnsweredBy'].present? && params['AnsweredBy'] == 'machine'
      # Hang up and call again if first attempt
      # Otherwise notify other caller that there was no answer
      handle_failed_call
    else
      render :nothing => true
    end
  end

  # Will say the message and then hang up
  def other_party_unavailable
    @say = "Sorry but the #{@caller_role == :from ? 'founder' : 'mentor'} could not make the call."
    # Update state of receiver to say they have received message and call is considered completed for them
    # Unfortunately can't use send method to set a value on the bitmask attributes
    if @opposite_role == :from
      @call.from_state = :completed
    elsif @opposite_role == :to
      @call.to_state = :completed
    end
    render :action => 'other_party_unavailable.xml.builder'
  end

  def connected
    if @caller_role == :to
      @call.update_attribute(:to_state, :connected)
      
      if @call.from_state != [:connected]
        # Schedule call to be disconnected in 20 mins (or whatever duration of call is set at)
        @call.schedule_disconnect
        
        # Connect both parties together
        @phone = @call.from.phone
        render :action => 'dial.xml.builder'
      else
        # Error - other party was not connected for some reason
        render :nothing => true
      end
      return
    elsif @caller_role == :from
      @call.update_attribute(:from_state, :connected)
    end
    render :nothing => true
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
    state = @call.send("#{@caller_role}_state").first
    if state == :first_attempt
      new_state = :second_attempt
      @call.perform_call_to_user(:from)
    elsif state == :second_attempt
      # Update state
      new_state = :failed
      
      # Notify other caller that it has failed
      @twilio_call = @call.twilio_call
      @twilio_call.redirect_to(other_party_unavailable_calls_path)

    end
    if @caller_role == :from
      @call.from_state = new_state
    elsif @caller_role == :to
      @call.to_state = new_state
    end
    @call.save
    render :nothing => true
  end

  def load_call
    @number = params["To"] # since we're always calling from our number to their number
    @call_sid = params["CallSid"]
    @call = Call.get_call_for_sid(@call_sid) unless @call_sid.blank?
    if @call.blank?
      render :nothing => true
      return false
    end
    @caller_role = @call.caller_role_from_number(@number)
    @opposite_role = @caller_role == :from ? :to : :from
    true
  end
end
