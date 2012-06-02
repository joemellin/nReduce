class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name

  def mailchimp!
    return true if mailchimped?
    return false unless email.present?
    return false unless Settings.mailchimp.enabled

    h = Hominid::API.new(Settings.mailchimp.api_key)
    h.list_subscribe(Settings.mailchimp.everyone_list_id, email, {}, "html", false)

    h.list_subscribe(Settings.mailchimp.startup_list_id, email, {}, "html", false) if startup?
    h.list_subscribe(Settings.mailchimp.mentor_list_id, email, {}, "html", false) if mentor?

    self.mailchimped = true
    self.save!

  rescue => e
    Rails.logger.error "Unable put #{email} to mailchimp"
    Rails.logger.error e
  end
end
