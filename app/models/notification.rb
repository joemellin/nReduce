class Notification < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  belongs_to :user
  has_many :user_actions, :as => :attachable

  validates_presence_of :user_id
  validates_presence_of :attachable_id
  validates_presence_of :attachable_type

  # Resque queue name
  @queue = :notification_email

  scope :unread, where(:read_at => nil)
  scope :read, where('read_at IS NOT NULL')
  scope :ordered, order('created_at DESC')

    # Remember to update method in helpers/application_helper.rb with new object types if they are added for correct messaging
  def self.actions
    [:new_checkin, :relationship_request, :relationship_approved, :mentorship_approved, :new_comment, :new_nudge]
  end

   # Pass in a user to notify, related object (ex: a relationship) and the action performed, and this will:
   # - Create a notification object that is displayed to user on the site
   # - Adds email to resque queue, if their notification settings allow it
   # Possible actions: new_checkin, relationship_request, relationship_approved, new_comment
  def self.create_and_send(user, object, action, message = nil)
    return unless Notification.actions.include?(action)
    n = Notification.new
    n.attachable = object
    n.user = user
    n.action = action
    n.message = message || "You have a new #{object.class.to_s.downcase}"
    if n.save
      n.user.update_unread_notifications_count
      Resque.enqueue(Notification, n.id) if n.email_user?
    end
    n
  end

  # Notifies all connected startup team members of new checkin
  def self.create_for_new_checkin(checkin)
    startups_to_notify = checkin.startup.connected_to
    users_to_notify = User.where(:startup_id => startups_to_notify.map{|s| s.id }).all
    users_to_notify.each do |u|
      Notification.create_and_send(u, checkin, :new_checkin)
    end
  end

  # Notify requested entity that other entity wants to be connected
  def self.create_for_relationship_request(relationship)
    connected_with = relationship.connected_with
    if connected_with.is_a?(Startup)
      connected_with.team_members.each do |u|
        Notification.create_and_send(u, relationship, :relationship_request)
      end
    elsif connected_with.is_a?(User)
      Notification.create_and_send(connected_with, relationship, :relationship_request)
    else
      raise "Relationship type not added to notifications"
    end
  end

  def self.create_for_relationship_approved(relationship)
    entity = relationship.entity
    if entity.is_a?(Startup)
      entity.team_members.each do |u|
        Notification.create_and_send(u, relationship, :relationship_approved)
      end
    elsif entity.is_a?(User) and entity.mentor?
      Notification.create_and_send(entity, relationship, :mentorship_approved)
    else
      raise "Relationship type not added to notifications"
    end
  end

  def self.create_for_new_comment(comment)
    startup = comment.checkin.startup
    startup.team_members.each do |u|
      Notification.create_and_send(u, comment, :new_comment) unless u.id == comment.user_id
    end
  end

    # Notify this person that someone has replied to their comment
  def self.create_for_comment_reply(new_comment, reply_to_user)
    Notification.create_and_send(reply_to_user, new_comment, :new_comment) unless reply_to_user.id == new_comment.user_id
  end

  # only intended for awesomes on checkins
  def self.create_for_new_awesome(awesome)
    awesome.awsm.startup.team_members.each do |u|
      n = Notification.new
      n.attachable = awesome
      n.user = u
      n.message = "#{awesome.user.name} thought your checkin was awesome!"
      n.save
    end
  end

  # Nudges a startup to finish their checkin
  def self.create_for_new_nudge(nudge)
    nudge.startup.team_members.each do |u|
       Notification.create_and_send(u, nudge, :new_nudge) unless u.id == nudge.from_id
    end
  end

  # Delivers notification email
  def self.perform(notification_id)
    n = Notification.find(notification_id)
    if n.emailed?
      # Somehow it got queued again - but was already emailed
      logger.info "Notification #{n.id}: Email already delivered to #{n.user.email}"
      return true
    else
      # Make sure it responds to action
      if UserMailer.respond_to?(n.action.to_sym)
        deliver = UserMailer.send(n.action.to_sym, n).deliver
        if deliver
          n.update_attribute('emailed', true)
          return deliver
        else
          # TODO : re-queue if fail delivery?
          logger.warn "Notification #{n.id}: Email could not be delivered to #{n.user.email}"
          return false
        end
      else
        logger.warn "Notification #{n.id}: Email template could not be found for notification action #{n.action}"
        return false
      end
    end
  end

  # Mark all notifications as read for a user
  def self.mark_all_read_for(user)
    Notification.transaction do
      user.notifications.unread.each{|n| n.read_at = Time.now; n.save }
    end
    true
  end

  # Checkins user settings to see if they want to be emailed on this action
  def email_user?
    self.user.email_for?(self.attachable_type.downcase)
  end
end
