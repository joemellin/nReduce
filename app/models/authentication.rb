class Authentication < ActiveRecord::Base
  belongs_to :user

  attr_accessible :provider, :uid, :token, :secret

  scope :provider, lambda{ |prov| where(:provider => prov) }
  scope :ordered, order('created_at DESC')
  
  def provider_name
    if provider == 'open_id'
      "OpenID"
    else
      provider.titleize
    end
  end
end
