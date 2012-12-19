class UsabilityTestRequest < Request
  # Uncomment this in each child class so we can use STI and have routes work properly
  def self.model_name
    Request.model_name
  end
  
  def self.defaults
    {
     :price => 5,
     :pricing_unit => 'usability testers',
     :pricing_step => 1,
     :response_expires_in => 60.minutes,
     :title_required => false,
     :questions => [["URL", 'string'], ["Instructions", 'text']]
    }
  end

  protected

  def perform_request_specific_setup_tasks
    # initialize screenr?

    true
  end
end