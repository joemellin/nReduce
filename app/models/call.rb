class Call < ActiveRecord::Base
  belongs_to :from, :class_name => 'User'
  belongs_to :to, :class_name => 'User'
  #
  # idea: send calendar invite to mentor after scheduling
  #

  attr_accessible :to_state, :from_state

  bitmask :state, :as => [:scheduled, :completed, :canceled]
  bitmask :from_state, :as => [:scheduled, :first_attempt, :second_attempt, :connected, :completed, :failed]
  bitmask :to_state, :as => [:scheduled, :first_attempt, :second_attempt, :connected, :completed, :failed]
  bitmask :scheduled_state, :as => [:asked, :day, :time, :completed, :declined]

  @queue = :calls

  def self.perform(call_id, action = :reminder)
    c = Call.find(call_id)
    # Remind both parties that call is about to happen
    if action == :reminder
      c.send_reminder
    # Perform call
    elsif action == :call
      c.perform_call_to_user(:to)
    elsif action == :disconnect
      tc = self.twilio_call
      tc.hangup unless tc.blank?
    end
  end

  def self.scheduled_call_states
    Call.values_for_scheduled_state
  end

  # Send sms message chain to user to get them to choose the time
  def self.schedule_with_user(user)
    c = Call.new
    c.from = user
    c.scheduled_state = :asked
    c.save
    c.send_message_for_state
  end

  # Got a response from a user, need to identify what step they are at and send appropriate message/collect data
  def self.respond_to_message(phone, message)
    # First get their user state
    user = User.find_by_phone(phone)
    call = Call.current_call_for_user(user)

    resend = false
    # Save data if necessary
    case call.scheduled_state.first
    when :asked
      if message.downcase.include?('y')
        call.scheduled_state = :day
      elsif message.downcase.include?('n')
        call.scheduled_state = :declined
      else
        # didn't recognize the response, send message again
        resend = true
      end
    when :day
      if message.blank?
        resend = true
      else
        call.data = message.strip
        call.scheduled_state = :time
      end
    when :time
      if message.blank?
        resend = true
      else
        # set scheduled at
        if call.set_scheduled_at_from_string(call.data, message.strip) == false
          resend = true
        else
          call.data = "#{call.data} #{message.strip}"
          call.scheduled_state = :completed
        end
      end
    when :completed
      # somehow got triggered again, just ignore
    else
      # unrecognized state
    end
    call.save
    call.send_message_for_state(resend)
  end

  # Gets the call if they are the 'from' user
  def self.current_call_for_user(user)
    Call.where(:from_id => user.id).order('created_at DESC').first
  end

  def self.get_call_for_sid(sid)
    Call.where(:sid => sid).first
  end

  # Returns symbol of caller role (either :from or :to)
  def caller_role_from_number(phone)
    return :from if self.from.phone.include?(phone)
    return :to if self.to.phone.include?(phone)
    return nil
  end

  # Sets the scheduled at time for this week from a string, ex: Th 500pm
  # Need to accomodate for user's time zone
  def set_scheduled_at_from_string(day, time)
    begin
      day_of_week = ['mo', 'tu', 'we', 'th', 'fr', 'sa', 'su'].index(day.downcase)
      tmp_time = "#{time[0..(time.size - 3)]} #{time.last(2)}"
      beginning = Time.now.beginning_of_week
      tmp_time = Time.parse("#{beginning.year}-#{beginning.month}-#{beginning.day} #{tmp_time}")
      time = tmp_time + day_of_week.days
      return self.scheduled_at = time
    rescue
      #
    end
    false
  end

  # Schedule this call in the future
  def schedule_with(to, duration = 20)
    self.to = to
    self.duration = duration
    
    # Set up reminder 10 minutes before call
    Resque.enqueue_at(self.scheduled_at - 10.minutes, Call, self.id, :reminder)

    # Set up call to happen at scheduled time
    Resque.enqueue_at(self.scheduled_at, Call, self.id, :call)

    # Send sms to from to notify call has been scheduled
    msg = "A founder has been confirmed to talk with you at #{self.scheduled_at}"
    TwilioClient.account.sms.messages.create(:from => Settings.apis.twilio.phone, :to => self.from.phone, :body => msg)
    
    self.confirmed = true
    self.save
    self
  end

  # Sends a message to the user for this current state
  def send_message_for_state(resend = false)
    msg = case self.scheduled_state.first
      when :asked then 'Would you like to mentor a startup this week? Please respond with: yes or no'
      when :day then 'What day works for you? Enter one: Mo Tu We Th Fr Sa Su'
      when :time then 'What time works for you? ex: 800am or 330pm'
      when :completed then "Thanks! You have set yourself to be available at #{self.scheduled_at}"
      else
    end
    msg = "Sorry didn't catch that. #{msg}" if resend
    TwilioClient.account.sms.messages.create(:from => Settings.apis.twilio.phone, :to => self.from.phone, :body => msg)
  end

  # Send reminder to people receiving call
  def send_reminder
    msg = "Heads up your mentor call will begin in 10 minutes"
    TwilioClient.account.sms.messages.create(:from => Settings.apis.twilio.phone, :to => self.from.phone, :body => msg)
    TwilioClient.account.sms.messages.create(:from => Settings.apis.twilio.phone, :to => self.to.phone, :body => msg)
  end

  # Returns instance of call using SID
  def twilio_call
    TwilioClient.account.calls.get(self.sid) unless self.sid.blank?
  end

  def schedule_disconnect
    Resque.enqueue_in(self.duration.minutes, Call, self.id, :disconnect)
  end

  def perform_call_to_user(caller_role = :to)
    state = self.send("#{caller_role}_state").first
    if state.blank? || state == :first_attempt
      number = self.send(caller_role).phone
      call = TwilioClient.account.calls.create(
        :from => Settings.apis.twilio.phone,
        :to => number,
        :url => 'http://www.nreduce.com/calls/connected',
        :fallback_url => 'http://www.nreduce.com/calls/failed',
        :status_callback => 'http://www.nreduce.com/calls/completed',
        :if_machine => 'Continue',
        :timeout => 15 # time out after 15 seconds
      )
      self.sid = call.sid
      new_state = :first_attempt
    elsif state == :second_attempt
      new_state = :failed
    end
    if caller_role == :to
      self.to_state = new_state
    elsif caller_role == :from
      self.from_state = new_state
    end
    self.save
    # http://www.twilio.com/docs/api/rest/participant
  end
end
