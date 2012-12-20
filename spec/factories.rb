# http://stackoverflow.com/questions/2015473/using-factory-girl-in-rails-with-associations-that-have-unique-constraints-gett
# singleton which also regenerates the model if the db has been cleared since the last round of tests/specs:
saved_single_instances = {}
#Find or create the model instance
single_instances = lambda do |factory_key|
  begin
    saved_single_instances[factory_key].reload
  rescue NoMethodError, ActiveRecord::RecordNotFound  
    #was never created (is nil) or was cleared from db
    saved_single_instances[factory_key] = FactoryGirl.create(factory_key)  #recreate
  end
  return saved_single_instances[factory_key]
end

FactoryGirl.define do
  factory :startup do
    name 'nReduce'
    one_liner 'online startup incubator'
    elevator_pitch 'We help founders execute better by pairing them with other companies that give weekly feedback'
    industry_list 'startups, investing'
    setup [:profile, :invite_team_members, :intro_video]
    growth_model 1 
    stage 1
    company_goal 1
    factory :startup2 do
      name 'Facebook for Dummies'
      industry_list 'education, social networking'
    end
  end

  factory :user do
    name 'Testy McTesterson'
    email 'testy@mctesterson.com'
    password 'please'
    password_confirmation 'please'
    location 'Buenos Aires, Argentina'
    skill_list 'rails, firebreathing'
    pic 'test.png'
    setup [:account_type, :onboarding, :profile, :welcome]
    linkedin_url 'http://www.linkedin.com/me'
   # startup  { single_instances[:startup] }
    roles [:entrepreneur]
    factory :user2 do
      email 'bananas@tropical.com'
      name 'Tropical Bananas'
     # startup  { single_instances[:startup] }
    end
    factory :admin do
      email 'admin@nreduce.com'
      name "Admin"
      admin true
    end
    factory :mentor do
      email 'mentor@famousfounder.com'
      name "Famous Founder"
      roles [:mentor]
    end
    factory :investor do
      email 'investor@imrich.com'
      name "Investor Dude"
      roles [:investor]
    end
  end

  factory :checkin do
    startup { single_instances[:startup] }
    factory :submitted_checkin do
      start_focus 'To make awesome tests'
      before_video { FactoryGirl.create(:youtube) }
      factory :completed_checkin do
        after_video { FactoryGirl.create(:youtube, :youtube_url => 'http://www.youtube.com/watch?v=4vkqa230023') }
        end_comments 'We did it!'
      end
    end
  end

  factory :meeting do
    location_name 'San Francisco'
    venue_name 'WeWork'
    venue_address '2nd & Howard, SF, CA'
    attendees { [single_instances[:user], single_instances[:user2]] }
    organizer { FactoryGirl.create(:user, :email => 'awesome@organizer.com') }
  end

  factory :comment do
    checkin { create(:completed_checkin) }
    user { single_instances[:user] }
    content 'This is just some amazing progress'
  end

  factory :awesome do
    user { single_instances[:user] }
    checkin { single_instances[:checkin] }
  end

  factory :youtube do
    youtube_url 'http://www.youtube.com/watch?v=4vkqBfv8OMM'
  end

  factory :retweet_request do
    num 5
    data({'url' => 'https://twitter.com/statuses/1230930'})
  end

  factory :usability_test_request do
    num 2
    title 'Test out the new pac-man game!'
    data({'url' => 'http://nreduce.com/traction_machine', 'instructions' => 'See if you can post a request. Start a new retweet request. Enter this tweet url and post request for 1 user: http://twitter.com/statuses/1233129. Validate your request has been posted.'})
  end

  factory :rating do
    investor_id 1
    startup_id 1
    interested false
    feedback 1
    explanation "MyText"
  end
end