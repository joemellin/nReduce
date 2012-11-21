class Conversation < ActiveRecord::Base
  has_many :messages, :dependent => :destroy
  has_many :conversation_statuses, :dependent => :destroy

  serialize :participant_ids, Array

  accepts_nested_attributes_for :messages, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true

  validate :participants_are_present # and limits to 20 per conversation
  validate :message_is_present

  before_create :generate_conversation_statuses
  
  attr_accessible :participant_ids, :messages_attributes, :to, :updated_at

  attr_accessor :to

  # Start a new conversation between users or startups. If given a startup the message is effectively started between all the users on a startup
  def self.create(attrs = {})
    attrs[:participant_ids] ||= []

    # Hack to assign from dropdown - need a better way of submitting participant ids
    user_id = attrs[:to].split('-').last.strip if attrs[:to].present?
    attrs[:participant_ids] << user_id.to_i if user_id.present?

    # Check to see if a conversation already exists between these people, if so append message to that one
    c = Conversation.between(attrs[:participant_ids]) unless attrs[:participant_ids].blank?
    c.messages << Message.new(attrs[:messages_attributes]['0']) if c.present? && attrs[:messages_attributes].present?

    # Otherwise start a new one
    c ||= Conversation.new(attrs)
    c.save
    c
  end

  # What happens if the users on a startup change? Should message be just be between startups?
  # problem if the participant is just me it matches any convo i've had
  def self.between(participant_ids = [])
    return nil if participant_ids.size < 2
    num_participants = participant_ids.size
    cvs = ConversationStatus.where(:user_id => participant_ids).group(:conversation_id).count
    conv_id = nil
    cvs.each{|conv_id, count| return Conversation.find(conv_id) if count == num_participants }
    return nil
  end

  def latest_message
    self.messages.order('created_at DESC').first
  end

  # Will first load participants from participant_ids array, then users who are on startup_ids array
  # Can exclude a user by providing an integer id to the first param, without_user_id
  # Not sure this is the best way to do this - really shouldn't be caching participants across both conversation and conversation_status
  def participants(without_user_id = nil)
    users = User.where(:id => self.participant_ids)
    users = users.where(['id != ?', without_user_id]) if without_user_id.present?
    users
  end

  def startups(without_startup_id = nil)
    startups = Startup.joins('INNER JOIN users ON users.startup_id = startups.id').where("users.id IN (#{self.participant_ids.join(',')})").group('startups.id')
    startups = startups.where(['startups.id != ?', without_startup_id]) if without_startup_id.present?
    startups
  end

  protected

  def participants_are_present
    if self.participant_ids.blank?
      self.errors.add(:participant_ids, "can't be blank")
      false
    elsif self.participant_ids.present? && self.participant_ids.size > 20
      self.errors.add(:participant_ids, "can't be more than 20 people per message")
      false
    else
      # ensure they are unique
      self.participant_ids.uniq!
      true
    end
  end

  def message_is_present
    if self.new_record? && self.messages.blank?
      self.errors.add(:messages, 'must have at least one message')
      false
    else
      true
    end
  end

  # Generate conversation status for each participant
  def generate_conversation_statuses
    first_message = self.messages.first
    self.participants.each do |u|
      # Mark as read for user who sent message
      conversation_statuses << ConversationStatus.new(:user => u, :read_at => u.id == first_message.from_id ? Time.now : nil)
    end
  end
end
