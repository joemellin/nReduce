class Conversation < ActiveRecord::Base
  has_many :messages, :dependent => :destroy
  has_many :conversation_statuses, :dependent => :destroy
  belongs_to :latest_message, :class_name => 'Message'
  belongs_to :to_startup, :class_name => 'Startup'

  serialize :participant_ids, Array

  accepts_nested_attributes_for :messages, :reject_if => proc {|attributes| attributes.all? {|k,v| v.blank?} }, :allow_destroy => true

  validate :participants_are_present # and limits to 20 per conversation
  validate :message_is_present

  before_create :generate_conversation_statuses
  
  attr_accessible :participant_ids, :messages_attributes, :to_entity, :to, :updated_at, 
    :messages, :latest_message_id, :to_startup_id, :team_to_team

  attr_accessor :to_entity # accepts user_{id}, startup_{id}, or actual object
  attr_accessor :to # just for form to show to field, not actually used

  # Start a new conversation between users or startups. If given a startup the message is effectively started between all the users on a startup
  # To entity can either be a user or startup, or a string that represents them
  def self.create(attrs = {})
    attrs[:participant_ids] ||= []

    team_to_team = false

    # Assign participants from a dropdown
    if attrs[:to_entity].present?
      if attrs[:to_entity].is_a?(User)
        tmp = ['user', attrs[:to_entity].id]
      elsif attrs[:to_entity].is_a?(Startup)
        tmp = ['startup', attrs[:to_entity].id]
      else
        tmp = attrs[:to_entity].strip.split('_')
      end
      if tmp[0] == 'user' # Person to person message
        attrs[:participant_ids] << tmp[1] 
      elsif tmp[0] == 'startup'
        # Find all your co-founders
        your_team_ids = User.find(attrs[:participant_ids].first).startup.team_member_ids
        # Add everyone from to: startup
        attrs[:participant_ids] += Startup.find(tmp[1]).team_member_ids
        # Add co-founders at end
        attrs[:participant_ids] += your_team_ids
        team_to_team = true
      end
      attrs[:participant_ids] = Conversation.clean_ids(attrs[:participant_ids])
    end

    # Check to see if a conversation already exists between these people, if so append message to that one
    c = Conversation.between(attrs[:participant_ids]) unless attrs[:participant_ids].blank?
    c.messages << Message.new(attrs[:messages_attributes]['0']) if c.present? && attrs[:messages_attributes].present?
    c.messages << attrs[:messages].first if c.present? && attrs[:messages].present? && attrs[:messages].first.is_a?(Message)

    # Otherwise start a new one
    c ||= Conversation.new(attrs)
    c.team_to_team = attrs[:team_to_team] || team_to_team
    c.save
    c
  end

  # What happens if the users on a startup change? Should message be just be between startups?
  # problem if the participant is just me it matches any convo i've had
  def self.between(participant_ids = [])
    return nil if participant_ids.size < 2
    # Hack - but it works. Grab all conversations from first participant and iterate to see if any contain all
    cvs = ConversationStatus.where(:user_id => participant_ids.first).includes(:conversation)
    cvs.each{|cs| return cs.conversation if cs.conversation.participant_ids == participant_ids }
    return nil
  end

  def self.clean_ids(arr = [])
    arr.map{|id| id.to_i }.delete_if{|id| id.blank? || id == 0 }.uniq
  end

  def assign_latest_message
    self.latest_message = self.messages.order('created_at DESC').first
  end

  # Will first load participants from participant_ids array, then users who are on startup_ids array
  # Can exclude a user by providing an integer id to the first param, without_user_id
  # Not sure this is the best way to do this - really shouldn't be caching participants across both conversation and conversation_status
  def participants(without_user_id = nil)
    users = User.where(:id => without_user_id.present? ? self.participant_ids_without(without_user_id) : self.participant_ids)
    users
  end

  def participant_ids_without(user_id)
    self.participant_ids - [user_id]
  end

  def startups(without_startup_id = nil)
    startups = Startup.joins('INNER JOIN users ON users.startup_id = startups.id').where("users.id IN (#{self.participant_ids.join(',')})").group('startups.id')
    startups = startups.where(['startups.id != ?', without_startup_id]) if without_startup_id.present?
    startups
  end

  protected

  def participants_are_present
    if self.participant_ids.blank? || self.participant_ids.present? && self.participant_ids.size == 1
      self.errors.add(:participant_ids, "can't be blank")
      false
    elsif self.participant_ids.present?
      # Clean up - remove dupes, turn to integer
      self.participant_ids = Conversation.clean_ids(self.participant_ids)
      if self.participant_ids.size < 2
        self.errors.add(:participant_ids, "can't be blank")
      elsif self.participant_ids.size > 20
        self.errors.add(:participant_ids, "can't be more than 20 people per message")
        false
      else
        true
      end
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
