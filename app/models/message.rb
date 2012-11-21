class Message < ActiveRecord::Base
  belongs_to :from, :class_name => 'User'
  belongs_to :conversation

  attr_accessible :from, :from_id, :content, :conversation_id

  after_create :notify_recipients_of_message
  after_save :update_conversation_updated_time

  validates_presence_of :from_id
  validates_presence_of :content

  scope :ordered, order('created_at ASC')

  @queue = :message

  # Send user email that they have new message
  def self.perform(message_id, user_id)
    UserMailer.new_message(Message.find(message_id), User.find(user_id)).deliver
  end

  # All conversation participants minus person who sent message
  def recipients
    self.conversation.participants(self.from_id)
  end

  protected

  def update_conversation_updated_time
    self.conversation.update_attributes(:updated_at => Time.now, :latest_message_id => self.id) if self.conversation.present? && !self.conversation.new_record?
  end

  def notify_recipients_of_message
    self.recipients.each do |u|
      Resque.enqueue(Message, self.id, u.id) if u.email_for?(:message)
    end
  end
end


