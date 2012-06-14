class Notification < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :attachable, :polymorphic => true

  scope :unread, where(:read_at => nil)
  scope :ordered, order('created_at DESC')

  def self.create_and_send_for_object(object)
    n = Notification.new
    n.attachable = object
    n.user = object.user
    n.message = "You have a new #{object.class.to_s.downcase}"
  end
end
