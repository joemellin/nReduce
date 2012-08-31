Twitter.configure do |config|
  config.consumer_key = Settings.apis.twitter.consumer_key
  config.consumer_secret = Settings.apis.twitter.consumer_secret
  config.oauth_token = Settings.apis.twitter.oauth_token
  config.oauth_token_secret = Settings.apis.twitter.oauth_token_secret
end