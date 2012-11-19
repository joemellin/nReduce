class Conversation < ActiveRecord::Base
  has_many :messages
  has_many :conversation_statuses

  serialize :participant_ids, Array

  accepts_nested_attributes_for :messages, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true

  validates_presence_of :participant_ids

  before_create :generate_conversation_statuses
  
  attr_accessible :participant_ids, :messages

  # Start a new conversation between users or startups. If given a startup the message is effectively started between all the users on a startup
  def self.create(attrs = {})
    # Check to see if a conversation already exists between these people, if so append message to that one
    c = Conversation.between(attrs[:participant_ids]) unless attrs[:participant_ids].blank?
    # Otherwise start a new one
    c ||= Conversation.new(attrs)
    c.save
    c
  end

  # What happens if the users on a startup change? Should message be just be between startups?
  def self.between(participant_ids = [])
    num_participants = participant_ids.size
    cvs = ConversationStatus.where(:user_id => participant_ids).group(:conversation_id).count
    conv_id = nil
    cvs.each{|conv_id, count| return Conversation.find(conv_id) if count == num_participants }
    return nil
  end

  # Will first load participants from participant_ids array, then users who are on startup_ids array
  # Can exclude a user by providing an integer id to the first param, without_user_id
  # Not sure this is the best way to do this - really shouldn't be caching participants across both conversation and conversation_status
  def participants(without_user_id = nil)
    users = User.where(:id => self.participant_ids)
    users = users.where(['id != ?', without_user_id]) if without_user_id.present?
    users
  end

  def startups
    Startup.joins('users ON users.startup_id = startups.id').where("users.id IN (#{self.participant_ids.join(',')})").group('startups.id')
  end

  protected

  # Generate conversation status for each participant
  def generate_conversation_statuses
    self.participants.each do |u|
      conversation_statuses << ConversationStatus.new(:user => u)
    end
  end
end
