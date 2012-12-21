class UsabilityTestRequest < Request
  # Uncomment this in each child class so we can use STI and have routes work properly
  def self.model_name
    Request.model_name
  end
  
  def self.defaults
    {
     :price => 5,
     :pricing_unit => 'usability tester',
     :pricing_step => 1,
     :response_expires_in => 60.minutes,
     :title_required => true,
     :video_required => true,
     # Warning: if you change keys, old requests will not display properly
     :questions => {
       'url' => ["URL of what you'd like tested", 'string', 'http://www.mysite.com/new_feature'],
       'instructions' => ["Instructions for your testers", 'text', 'What tasks do you want them to try and perform?']
      },
     :response_questions =>
      {
       'feedback' => ['Did anything confuse you? Do you have any other feedback?', 'text']
      }
    }
    # Warning: do not change questions array or else it will affect all previous responses
  end

  protected

  def perform_request_specific_setup_tasks
    # initialize screenr?

    true
  end
end