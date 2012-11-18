class Conversation < ActiveRecord::Base
  has_many :messages
  has_many :conversation_statuses

  serialize :user_ids
  serialize :startup_ids

  accepts_nested_attributes_for :messages, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true

  before_create :generate_conversation_statuses
  # attr_accessible :title, :body

  def participants
    User.find(self.user_ids)
  end

  def startups
    Startup.find(self.startup_ids)
  end

  protected

  # Generate conversation status for each participant
  def generate_conversation_statuses
    self.messages.first
  end
end
