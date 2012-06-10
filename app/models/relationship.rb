class Relationship < ActiveRecord::Base
  belongs_to :startup
  belongs_to :connected_with, :class_name => 'Startup'

  attr_accessible :startup_id, :connected_with_id, :status, :approved_at, :rejected_at

  # Statuses
  PENDING = 1
  APPROVED = 2
  REJECTED = 3

  scope :pending, where(:status => Relationship::PENDING)
  scope :approved, where(:status => Relationship::APPROVED)
  scope :rejected, where(:status => Relationship::REJECTED)

  # Start a relationship between two startups
  def self.start_between(startup, connect_with_startup)
    return if startup.id == connect_with_startup.id
    # Check if a relationship already exists
    existing = Relationship.between(startup, connect_with_startup)
    return existing unless existing.blank?
    # Create new pending relationship
    Relationship.create(:startup_id => startup.id, :connected_with_id => connect_with_startup.id, :status => Relationship::PENDING)
  end

    # Finds relationship between two startups
  def self.between(startup1, startup2)
    Relationship.where(:startup_id => startup1.id, :connected_with_id => startup2.id).first
  end

    # Returns all startups that this startup is connected to (approved status)
  def self.all_connections_for(startup)
    startup.relationships.approved.includes(:connected_with).map{|r| r.connected_with }
  end

    # Returns all startups that this startup has initiated, but are still pending
  def self.all_pending_relationships_for(startup)
    Relationship.where(:connected_with_id => startup.id).pending.includes(:startup)
  end

    # Returns all pending relationships that other startups have initiated with this startup
  def self.all_requested_relationships_for(startup)
    startup.relationships.pending.includes(:connected_with)
  end

  # Approve the friendship and create a record in the opposite direction so friendship is easy to query
  def approve!
    begin
      Relationship.transaction do
        self.update_attributes(:status => APPROVED, :approved_at => Time.now) unless self.approved?
        inv = self.inverse_relationship
        if !inv.blank?
          inv.update_attributes(:status => APPROVED, :approved_at => Time.now) unless inv.approved?
        else
          Relationship.create(:startup_id => connected_with_id, :connected_with_id => startup_id, :status => APPROVED, :approved_at => Time.now)
        end
      end
    rescue ActiveRecord::RecordNotUnique
      # Already approved don't need to do anything
    end
    true
  end

  # Reject the friendship, but don't delete records
  def reject!
    begin
      Relationship.transaction do
        self.update_attributes(:status => REJECTED, :rejected_at => Time.now) unless self.rejected?
        inv = self.inverse_relationship
        inv.update_attributes(:status => REJECTED, :rejected_at => Time.now) unless inv.blank? or inv.rejected?
      end
    rescue ActiveRecord::RecordNotUnique
      # Already rejected don't need to do anything
    end
    true
  end

  def inverse_relationship
    Relationship.where(:startup_id => connected_with_id, :connected_with_id => startup_id).first
  end

  def pending?
    self.status == PENDING
  end

  def approved?
    self.status == APPROVED
  end

  def rejected?
    self.status == REJECTED
  end
end
