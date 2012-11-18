class ConversationStatus < ActiveRecord::Base
  belongs_to :user
  belongs_to :conversation
  has_many :notifications, :as => :attachable

  bitmask :folder, :as => [:inbox, :archive, :trash]

  scope :unread, lambda{ where(:read_at => nil, :folder => :inbox) }

  # attr_accessible :title, :body
end
