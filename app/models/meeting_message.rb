class MeetingMessage < ActiveRecord::Base
  belongs_to :meeting
  belongs_to :user

  attr_accessible :subject, :body
  serialize :emailed_to

  validates_presence_of :body
  validates_presence_of :meeting_id

  after_create :notify_attendees

  @queue = :meeting_message

  # Resque method to send meeting reminder email to an individual attendee
  def self.perform(meeting_message_id, user_id)
    meeting_message = MeetingMessage.find(meeting_message_id)
    meeting = meeting_message.meeting
    user = User.find(user_id)
    UserMailer.meeting_reminder(user, meeting, meeting_message.body, meeting_message.subject).deliver
  end

  protected

  # Queue up all users to be notified
  def notify_attendees
    emailed_to = []
    self.meeting.attendees.select('id, email, settings').where('email IS NOT NULL').each do |u|
      if u.email_for?('meeting')
        Resque.enqueue(MeetingMessage, self.id, u.id)
        emailed_to.push(u.id)
      end
    end
    self.emailed_to = emailed_to
    self.save
  end
end
