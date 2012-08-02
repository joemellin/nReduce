class User < ActiveRecord::Base
  include Connectable # methods for relationships
  acts_as_mappable
  has_paper_trail
  belongs_to :startup
  belongs_to :meeting
  has_many :authentications, :dependent => :destroy
  has_many :organized_meetings, :class_name => 'Meeting', :foreign_key => 'organizer_id'
  has_many :sent_messages, :foreign_key => 'sender_id', :class_name => 'Message'
  has_many :received_messages, :foreign_key => 'recipient_id', :class_name => 'Message'
  has_many :comments
  has_many :notifications, :dependent => :destroy
  has_many :meeting_messages
  has_many :invites, :foreign_key => 'to_id', :dependent => :destroy
  has_many :sent_invites, :foreign_key => 'from_id', :class_name => 'Invite'
  has_many :awesomes
  has_many :sent_nudges, :class_name => 'Nudge', :foreign_key => 'from_id'
  has_many :user_actions, :as => :attachable, :dependent => :destroy
  has_many :relationships, :as => :entity, :dependent => :destroy
  has_many :connected_with_relationships, :as => :connected_with, :class_name => 'Relationship', :dependent => :destroy
  has_many :screenshots

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable #, :confirmable #, :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :twitter, :email, :email_on, :password, :password_confirmation, :remember_me, :name, :skill_list, :industry_list, :startup, :mentor, :investor, :location, :phone, :startup_id, :settings, :meeting_id, :one_liner, :bio, :facebook_url, :linkedin_url, :github_url, :dribbble_url, :blog_url, :pic, :remote_pic_url, :pic_cache, :remove_pic, :intro_video_url
  attr_accessor :profile_fields_required

  serialize :settings, Hash

  validates_presence_of :name
  validate :email_is_not_nreduce
  validate :check_video_urls_are_valid
  validates_length_of :bio, :minimum => 100, :too_short => "needs to be at least 100 characters", :if => :profile_fields_required?
  validates_presence_of :pic, :if => :profile_fields_required?
  validates_presence_of :location, :if => :profile_fields_required?
  validates_presence_of :skill_list, :if => :profile_fields_required?
  validates_presence_of :linkedin_url, :if => :profile_fields_required?

  before_create :set_default_settings
  after_create :mailchimp!
  before_save :geocode_location

  acts_as_taggable_on :skills, :industries

  scope :mentor, where(:mentor => true)

  mount_uploader :pic, PicUploader # carrierwave file uploads

  # important that you keep the order the same on this array - uses bitmask_attributes gem
  # adds methods and scopes: https://github.com/joelmoss/bitmask_attributes
  bitmask :roles, :as => [:admin, :entrepreneur, :mentor, :investor, :nreduce_mentor, :spectator]
  bitmask :onboarded, :as => [:startup, :mentor, :nreduce_mentor, :investor]
  bitmask :email_on, :as => [:docheckin, :comment, :meeting, :checkin, :relationship]
  bitmask :setup, :as => [:account_type, :onboarding, :profile, :invite_startups, :welcome]

  # Number of startups an investor can contact per week
  INVESTOR_STARTUPS_PER_WEEK = 5

  searchable do
    # full-text search fields - can add :stored => true if you don't want to hit db
    text :name
    text :location
    text :skills_cached, :stored => true do
      self.skills.map{|t| t.name.titleize }.join(', ')
    end
    text :industries_cached, :stored => true do
      self.industries.map{|t| t.name.titleize }.join(', ')
    end

    # filterable fields
    double  :rating
    integer :meeting_id
    boolean :is_mentor do
      self.mentor?
    end
    boolean :has_pic do
      self.pic?
    end
    integer :num_mentoring, :stored => true do
      if self.mentor?
        connected_with_relationships.startup_to_user.approved.count
      else
        0
      end
    end
    boolean :nreduce_mentor do
      roles?(:nreduce_mentor) && onboarded?(:mentor)
    end
    integer :skill_tag_ids, :multiple => true, :stored => true do
      self.skills.map{|t| t.id }
    end
    integer :industry_tag_ids, :multiple => true, :stored => true do
      self.industries.map{|t| t.id }
    end
    string :sort_name do
      name.blank? ? '' : name.downcase.gsub(/^(an?|the)/, '')
    end
  end

  def self.email_on_options
    {
      :docheckin => 'Reminder to Check-in',
      :comment => 'New Comment',
      :meeting => 'Meeting Reminder',
      :checkin => 'New Checkin',
      :relationship => 'Relationships'
    }
  end

  def self.default_email_on
    self.email_on_options.keys
  end

  def self.force_email_on
    [:nudge, :user] # user is new mentor
  end

  def self.user_countries
    countries = []
    User.where('lat IS NOT NULL').each do |u|
      country = nil
      response = Net::HTTP.get_response(URI.parse('http://ws.geonames.org/countryCode?lat=' + u.lat.to_s + '&lng='  + u.lng.to_s))
      country = response.body.strip unless response.body.blank?
      countries << country unless country.blank?
    end
    countries
  end

  def can_access_chat?
    self.created_at < Time.parse('2012-07-24 00:00:00')
  end

  def profile_fields_required?
    self.profile_fields_required == true
  end

    # Calculates profile completeness for all factors
    # Returns total percent out of 1 (eg: 0.25 for 25% completeness)
  def profile_completeness_percent
    total = completed = 0.0
    self.profile_elements.each do |element, is_completed|
      total += 1.0
      completed += 1.0 if is_completed
    end
    (completed / total).round(2)
  end

  def required_profile_elements
    [:name, :email, :pic, :bio, :linkedin_url, :skill_list, :location]
  end

  def profile_elements
    {
      :email => !self.email.blank?, 
      :picture => self.pic?, 
      :bio => (!self.bio.blank? and (self.bio.size > 40)), 
      :linked_in => !self.linkedin_url.blank?,
      :skills => !self.skill_list.blank?
    }
  end

  def mentor?
    roles?(:mentor) or roles?(:nreduce_mentor)
  end

  def investor?
    roles?(:investor)
  end

  def entrepreneur?
    roles?(:entrepreneur)
  end

  # LEGACY METHODS
  def num_onboarding_steps # needs to be one more than actual steps
    7
  end

  def onboarding_complete?
    self.onboarding_step >= self.num_onboarding_steps
  end
  # END LEGACY METHODS

    # Skip step 4 and 5 if user is not an nreduce mentor
  def skip_onboarding_step?(step)
    self.mentor? and !self.roles?(:nreduce_mentor) and [4,5].include?(step)
  end

  def has_startup_or_is_mentor?
    !self.startup_id.blank? or self.mentor?
  end

  def received_nudges
    self.startup.nudges
  end

  def settings
    self['settings'].blank? ? [] : self['settings']
  end

  def update_unread_notifications_count
    self.unread_nc = self.notifications.unread.count
    self.save
  end

  def mark_all_notifications_read
    if Notification.mark_all_read_for(self)
      self.unread_nc = 0
      self.save
    else 
      false
    end
  end

    # Returns boolean if user should be emailed for a specific action (action being the object class)
  def email_for?(class_name)
    begin
      return true if User.force_email_on.include?(class_name.to_sym)
      !self.email.blank? and self.email_on?(class_name.downcase.to_sym)
    rescue # in case array isn't set
      false
    end
  end

  def first_name
    self.name.blank? ? '' : self.name.sub(/\s+.*/, '')
  end

  def awesome_id_for_object(object)
    cached = self.cached_awesome_ids
    # when hash is retrieved from cache, id keys are converted to strings so have to look for string
    return cached[object.class.to_s][object.id.to_s] if cached[object.class.to_s] and cached[object.class.to_s][object.id.to_s]
    return nil
  end

    # returns hash all objects this user has 'awesomed' organized by object class. also includes awesome id
    # eg {:comment => {23 (comment id) => 12 (awesome id), 12 => 52}, :checkin => {56 => 54, 55 => 33}}
  def cached_awesome_ids
    Cache.get(['awesome_ids', self]){
      ids = {}
      self.awesomes.each{|a| ids[a.awsm_type] ||= {}; ids[a.awsm_type][a.awsm_id.to_s] = a.id }
      ids
    }
  end

  def commented_on_checkin_ids
    Cache.get(['cids', self]){
      self.comments.map{|c| c.checkin_id }
    }
  end

  def mailchimp!
    return true if mailchimped?
    return false unless email.present?
    return false unless Settings.apis.mailchimp.enabled

    h = Hominid::API.new(Settings.apis.mailchimp.api_key)

    #h.list_subscribe(Settings.apis.mailchimp.startup_list_id, email, {}, "html", false) unless self.startup_id.blank?
    #h.list_subscribe(Settings.apis.mailchimp.mentor_list_id, email, {}, "html", false) if self.mentor?
    h.list_subscribe(Settings.apis.mailchimp.everyone_list_id, email, {}, "html", false)

    self.mailchimped = true
    self.save!

  rescue => e
    Rails.logger.error "Unable put #{email} to mailchimp"
    Rails.logger.error e
  end


  # Returns true if the user has set everything up for the account (otherwise forces user to go through flow)
  def account_setup?
    if setup?(:account_type, :onboarding, :profile, :welcome)
      return true if roles?(:entrepreneur) and !self.startup.blank? and self.startup.account_setup?
      return true if (roles?(:mentor) or roles?(:investor)) and setup?(:invite_startups)
    end
    false
  end

  # Returns the current controller / action name as an array of [:controller, :action] - ex: [:onboarding, :user], or [:profile, :startup]
  # Will test various conditions to see if it is complete
  # first checks setup field so we don't have to perform db queries if they've completed that step
  def account_setup_action
    return [:complete] if account_setup?
    if !setup?(:account_type)
      if self.roles.blank?
        return [:users, :account_type]
      else
        self.setup << :account_type
        self.save
      end
    end
    if roles?(:spectator)
      return [:users, :spectator]
    end
    if !setup?(:onboarding)
      if self.onboarded.blank?
        return [:onboard, :start]
      else
        self.setup << :onboarding
        self.save
      end
    end
    if !setup?(:profile)
      if self.profile_completeness_percent < 1.0
        return [:users, :edit]
      else
        self.setup << :profile
        self.save
      end
    end
    if roles?(:entrepreneur)
      self.startup = Startup.new if startup_id.blank?
      stage = self.startup.account_setup_action
      return stage unless stage.first == :complete # return startup stage unless complete
    end
    return [:startups, :invite] if (roles?(:mentor) or roles?(:investor)) and !setup?(:invite_startups)
    if !setup?(:welcome)
      return [:users, :welcome]
    end
    # If we just completed everything pass that back
    return [:complete] if account_setup?
    nil
  end
  
  def set_account_type(account_type = nil, reset = false)
    self.roles = nil if reset
    unless account_type.blank?
      self.roles << account_type.to_sym
      self.setup << :account_type
    end
  end

  def onboarding_completed!(onboarding_type)
    self.onboarded << onboarding_type.to_sym
    save!
  end

  def invited_startups!
    self.setup << :invite_startups
    save!
  end

  def setup_complete!
    self.setup << :welcome
    if self.save
      self.startup.generate_suggested_connections(10) unless self.startup.blank?
    end
  end

  # Returns symbol for current onboarding type if user hasn't set up account yet
  # If they've already set up 
  def onboarding_type
    return :startup if entrepreneur?
    return :mentor if mentor?
    return :investor if investor?
    return nil
  end

  # Method for investors - to see how many startups they have connected with this week
  # Week is based on checkin cycle, so it starts after "after" video is done
  def num_startups_connected_with_this_week
    self.relationships.where(:connected_with_type => 'Startup').where(['pending_at >= ?', Checkin.prev_after_checkin]).pending.count
  end

  def can_connect_with_startups?
    self.num_startups_connected_with_this_week < User::INVESTOR_STARTUPS_PER_WEEK
  end

  #
  # LINKEDIN
  #

  def linkedin_authentication=(auth)
    @linkedin_authentication = auth
  end

  def linkedin_authentication
    @linkedin_authentication || self.authentications.provider('linkedin').first
  end

  def linkedin_client
    client = LinkedIn::Client.new
    auth = self.linkedin_authentication
    return client if !auth.blank? and client.authorize_from_access(auth.token, auth.secret)
    nil
  end

  def linkedin_profile
    client = self.linkedin_client
    return [] if client.nil?
    # Profile fields: https://developer.linkedin.com/documents/profile-fields
    self.linkedin_client.profile(:fields => %w(skills location headline summary picture-url))
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
    auth = Authentication.new(User.auth_params_from_omniauth(omniauth))
    authentications << auth
    begin
      # TWITTER
      if omniauth['provider'] == 'twitter'
        logger.info omniauth['info'].inspect
        self.name = omniauth['info']['name'] if name.blank? and !omniauth['info']['name'].blank?
        #self.external_pic_url = omniauth['info']['image'] unless omniauth['info']['image'].blank?
        self.location = omniauth['info']['location'] if !omniauth['info']['location'].blank?
        self.twitter = omniauth['info']['nickname']
      elsif omniauth['provider'] == 'linkedin'
        self.linkedin_authentication = auth
        self.name = omniauth['info']['name'] if name.blank? and !omniauth['info']['name'].blank?
        #self.external_pic_url = omniauth['info']['image'] unless omniauth['info']['image'].blank?
        self.linkedin_url = omniauth['info']['urls']['public_profile'] unless omniauth['info']['urls'].blank? or omniauth['info']['urls']['public_profile'].blank?
        # Fetch profile from API
        profile = self.linkedin_profile
        unless profile.blank?
          self.skill_list = profile.skills.all.map{|s| s.skill.name } if self.skill_list.blank? and !profile.skills.blank?
          # applying location from IP instead for now
          #self.location = "#{profile.location.name}, #{profile.location.country.code}" if self.location.blank? and !profile.location.blank?
          self.bio = profile.summary if self.bio.blank?
          self.one_liner = profile.headline if self.one_liner.blank?
        end
      # FACEBOOK
      elsif omniauth['provider'] == 'facebook'
        self.name = omniauth['user_info']['name'] if name.blank? and !omniauth['user_info']['name'].blank?
        if self.email.blank?
          self.email = omniauth['extra']['user_hash']['email'] if omniauth['extra'] && omniauth['extra']['user_hash'] && !omniauth['extra']['user_hash']['email'].blank?
          self.email = omniauth['user_info']['email'] unless omniauth['user_info']['email'].blank?
        end
        self.email = 'null@null.com' if self.email.blank?
        if omniauth['extra']['user_hash']['location'] and !omniauth['extra']['user_hash']['location']['name'].blank?
          self.location = omniauth['extra']['user_hash']['location']['name']
        end
      end
    rescue
      logger.warn "ERROR applying omniauth with data: #{omniauth}"
    end
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

  def internal_email
    "#{twitter || self.id}@users.nreduce.com"
  end

  def hipchat_name
    n = !self.name.blank? ? self.name : self.twitter.sub('@', '')
    s = self.startup
    if !s.blank?
      n += " | #{s.name}"
    else
      # Name needs to have first and last name or else hipchat considers it invalid
      n += ' S12' if(n.split(/\s+/).size < 2)
    end
    n
  end

  def hipchat?
    hipchat_username.present?
  end

  def reset_hipchat_account!
    self.hipchat_username = nil
    self.generate_hipchat!
  end

  def generate_hipchat!
    return if hipchat?
    pass = NreduceUtil.friendly_token.to_s[0..8]
    prms = {:auth_token => Settings.apis.hipchat.token,
            :email => internal_email,
            :name => hipchat_name, 
            :title => 'nReducer', 
            :is_group_admin => 0,
            :password => pass, 
            :timezone => 'UTC'}

    # Have to post manually to API because for some reason gem doesn't pass auth token properly
    uri = URI.parse("https://api.hipchat.com/v1/users/create")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(prms)
    response = http.request(request)
    if response.code == '200'
      self.hipchat_username = internal_email
      self.hipchat_password = pass
      self.save!
    else
      false
    end
    # hipchat = HipChat::API.new(Settings.apis.hipchat.token)
    # pass = NreduceUtil.friendly_token.to_s[0..8]
    # if hipchat.users_create(internal_email, name, 'nReducer', 0, pass)
    #   self.hipchat_username = internal_email
    #   self.hipchat_password = pass
    #   self.save!
    # else
    #   false
    # end
  end

  def geocode_from_ip(ip_address)
    begin
      res = User.geocode(ip_address)
      unless res.blank?
        self.location = [res.city, res.state, res.country_code].delete_if{|i| i.blank? }.join(', ')
        return true
      end
    rescue
      # do nothing
    end
    false
  end

  protected

  def email_is_not_nreduce
    if !self.email.blank? and self.email.match(/\@\w+\.nreduce\.com$/) != nil
      self.errors.add(:email, 'is not valid')
      false
    else
      true
    end
  end

  def set_default_settings
    self.email_on = User.default_email_on
  end

  def geocode_location
    return true if !Rails.env.production? or self.location.blank? or (!self.location_changed? and !self.lat.blank?)
    begin
      res = User.geocode(self.location)
      self.lat, self.lng = res.lat, res.lng
    rescue
      self.errors.add(:location, "could not be geocoded")
    end
  end

  def check_video_urls_are_valid
    err = false
    if !intro_video_url.blank? and !Youtube.valid_url?(intro_video_url)
      self.errors.add(:intro_video_url, 'invalid Youtube URL')
      err = true
    end
    err
  end
end
