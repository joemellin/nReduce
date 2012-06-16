class Notification < ActiveRecord::Base
  belongs_to :attachable, :polymorphic => true
  belongs_to :user

  validates_presence_of :user_id
  validates_presence_of :attachable_id
  validates_presence_of :attachable_type

  # Resque queue name
  @queue = :notification_email

  scope :unread, where(:read_at => nil)
  scope :ordered, order('created_at DESC')

  def self.actions
    [:new_checkin, :relationship_request, :relationship_approved, :new_comment]
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
      Resque.enqueue(Notification, n.id) if n.email_user?
    end
    n
  end

  # Notifies all connected startup team members of new checkin
  def self.create_for_new_checkin(checkin)
    startups_to_notify = checkin.startup.connected_to
    users_to_notify = User.select('id, email, settings').where(:startup_id => startups_to_notify.map{|s| s.id }).all
    users_to_notify.each do |u|
      Notification.create_and_send(u, checkin, :new_checkin)
    end
  end

  # Notify requested startup that another startup wants to be connected
  def self.create_for_relationship_request(relationship)
    Notification.create_and_send(relationship.connected_with, relationship, :relationship_request)
  end

  def self.create_for_relationship_approved(relationship)
    Notification.create_and_send(relationship.startup, relationship, :relationship_approved)
  end

  def self.create_for_new_comment(comment)
    Notification.create_and_send(comment.checkin, comment, :new_comment)
  end

  # only intended for awesomes on checkins
  def self.create_for_new_awesome(awesome)
    awawesome.awsm
    awesome.awsm.startup.team_members.each do |u|
      n = Notification.new
      n.attachable = awesome
      n.user = u
      n.message = "#{awesome.user.name} thought your checkin was awesome!"
      n.save
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

  # Checkins user settings to see if they want to be emailed on this action
  def email_user?
    self.user.email_for?(self.attachable_type.downcase)
  end
end
