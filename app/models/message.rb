class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :recipient, :class_name => 'User'
  has_many :notifications, :as => :attachable
  has_many :user_actions, :as => :attachable

  attr_accessible :subject, :body, :recipient_id

  scope :unread, lambda{ where(:read_at => nil, :folder => Message.folders('Inbox')) }
  scope :inbox, lambda{ where(:folder => Message.folders('Inbox')) }
  scope :archive, lambda{ where(:folder => Message.folders('Archive')) }
  scope :trash, lambda{ where(:folder => Message.folders('Inbox')) }

  # Folders
  def self.folders
    {'Inbox' => 1,'Archive' => 2, 'Trash' => 3}
  end
end
