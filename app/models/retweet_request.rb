class RetweetRequest < Request
  # Uncomment this in each child class so we can use STI and have routes work properly
  def self.model_name
    Request.model_name
  end

  def self.defaults
    {
     :price => 1,
     :pricing_unit => 'followers',
     :pricing_step => 100,
     :response_expires_in => 30.minutes,
     :title_required => false,
     :video_required => false,
     # Warning: if you change keys, old requests will not display properly
     :questions => {
       'url' => ["Enter the URL of the tweet you would like to have Retweeted:", 'string', 'https://twitter.com/nReduce/status/274112721451102208']
      },
     :response_questions => {}
    }
  end

  def user_can_earn(user)
    num_followers = user.followers_count.present? ? user.followers_count : 0
    # price is per 100 followers
    avail = (user.followers_count.to_f / 100.0).floor
    avail = num if avail > num
    self.price * avail
  end

  protected

  def perform_request_specific_setup_tasks
    # Get tweet id and tweet content
    if Rails.env.production?
      self.extra_data ||= {}
      if self.data.present? && self.data['url'].present?
        match = self.data['url'].strip.match(/[0-9]+$/)
        self.extra_data['tweet_id'] = match[0] if match.present?
      end
      self.extra_data['tweet_content'] = Twitter.status(self.extra_data['tweet_id']).text unless self.extra_data['tweet_id'].blank?
      if self.extra_data['tweet_content'].blank?
        self.errors.add(:data, 'says: "You need to put in a valid Twitter URL"') 
        return false
      end
    end
    true
  end
end