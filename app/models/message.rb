class Message < ActiveRecord::Base
  belongs_to :from, :class_name => 'User'
  belongs_to :conversation

  attr_accessible :from, :from_id, :content

  before_create :notify_recipients_of_message

  validates_presence_of :from_id
  validates_presence_of :content

  scope :ordered, order('created_at DESC')

  def recipients
    self.conversation.participants(self.from_id)
  end

  protected

  def notify_recipients_of_message
    self.recipients.each do |u|
      Notification.create_for_new_message(self, u)
    end
  end
end


