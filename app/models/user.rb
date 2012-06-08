class User < ActiveRecord::Base
  belongs_to :location
  has_one :startup
  has_many :authentications
  has_one :attending_meeting, :class_name => 'Meeting', :through => :startup
  has_many :organized_meetings, :class_name => 'Meeting', :foreign_key => 'organizer_id'
  has_many :sent_messages, :foreign_key => 'sender_id'
  has_many :received_messages, :foreign_key => 'recipient_id'

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable #, :confirmable #, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :skill_list, :startup, :mentor, :investor, :location

  acts_as_taggable_on :skills

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

  #
  # OMNIAUTH LOGIC
  #
  
  def self.auth_params_from_omniauth(omniauth)
    prms = {:provider => omniauth['provider'], :uid => omniauth['uid']}
    if omniauth['credentials']
      prms[:token] = omniauth['credentials']['token'] if omniauth['credentials']['token']
      prms[:secret] = omniauth['credentials']['secret'] if omniauth['credentials']['secret']
    end
    prms
  end
  
  def apply_omniauth(omniauth)
    begin
      self.name = omniauth['user_info']['name'] if name.blank? && !omniauth['user_info']['name'].blank?
      if self.email.blank?
        self.email = omniauth['extra']['user_hash']['email'] if omniauth['extra'] && omniauth['extra']['user_hash'] && !omniauth['extra']['user_hash']['email'].blank?
        self.email = omniauth['user_info']['email'] unless omniauth['user_info']['email'].blank?
      end
      self.email = 'null@null.com' if self.email.blank?
      self.location = omniauth['extra']['user_hash']['location']['name']
    rescue
      logger.warn "ERROR applying omniauth with data: #{omniauth}"
    end
    authentications.build(User.auth_params_from_omniauth(omniauth))
  end

  def password_required?
    (authentications.empty? || !password.blank?) && super
  end
  
  def uses_password_authentication?
    !self.encrypted_password.blank?
  end
  
   # Returns boolean if user is authenticated with a provider 
   # Parameter: provider_name (string)
  def authenticated_for?(provider_name)
    authentications.where(:provider => provider_name).count > 0
  end
end
