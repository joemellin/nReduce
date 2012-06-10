class Message < ActiveRecord::Base
  belongs_to :sender, :class_name => 'User'
  belongs_to :recipient, :class_name => 'User'

  attr_accessible :subject, :body, :recipient_id

  # Folders
  FOLDERS = {'Inbox' => 1,'Archive' => 2, 'Trash' => 3}

  scope :unread, lambda{ where(:read_at => nil, :folder => Message::FOLDERS('Inbox')) }
  scope :inbox, lambda{ where(:folder => Message::FOLDERS('Inbox')) }
  scope :archive, lambda{ where(:folder => Message::FOLDERS('Archive')) }
  scope :trash, lambda{ where(:folder => Message::FOLDERS('Inbox')) }

end
