Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, Settings.apis.twitter.consumer_key, Settings.apis.twitter.consumer_secret
end