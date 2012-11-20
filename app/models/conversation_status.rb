class ConversationStatus < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation
  has_many :notifications, :as => :attachable

  bitmask :folder, :as => [:inbox, :archive, :trash]

  before_create :assign_default_folder

  scope :unread, lambda{ where(:read_at => nil, :folder => :inbox) }

  attr_accessible :user, :user_id, :read_at

  def mark_as_read!
    self.read_at = Time.now
    self.save
  end

  def archive!
    self.folder = :archive
    self.save
  end

  def trash!
    self.folder = :trash
    self.save
  end

  def unread?
    self.read_at.blank?
  end

  protected

  def assign_default_folder
    self.folder = :inbox
  end
end
