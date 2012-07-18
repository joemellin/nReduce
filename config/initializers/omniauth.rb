Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Settings.apis.twitter.consumer_key, Settings.apis.twitter.consumer_secret
  provider :linkedin, Settings.apis.linkedin.key, Settings.apis.linkedin.secret_key
end

LinkedIn.configure do |config|
  config.token = Settings.apis.linkedin.key
  config.secret = Settings.apis.linkedin.secret_key
end