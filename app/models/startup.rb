class Startup < ActiveRecord::Base
  belongs_to :user
  belongs_to :meeting

  attr_accessible :name, :team_members, :location_name, :product_url, :one_liner, :active, :industry_list, :technology_list, :ideology_list

  serialize :team_members

  validates_presence_of :name

  acts_as_taggable_on :industries, :technologies, :ideologies

  # Use S3 for production
  # http://blog.tristanmedia.com/2009/09/using-amazons-cloudfront-with-rails-and-paperclip/
  if Rails.env.production?
    Settings.paperclip_config.merge!({
      :storage => 's3',
      :s3_credentials => S3_CREDENTIALS,
      :s3_headers => { 'Expires' => 1.year.from_now.httpdate },
      :default_url => "http://www.nreduce.com/assets/avatar_:style.png",
      :s3_protocol => 'https'
    })
  end

  has_attached_file :logo, PAPERCLIP_CONFIG

  def team_members
    User.find(self['team_members'])
  end

    # Assign team members with an array of user ids
  def team_members=(user_ids = [])
    self['team_members'] = user_ids.uniq
  end

  def primary_contact
    self.user
  end
end
