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
    growth_model 1 
    stage 1
    company_goal 1
    factory :startup2 do
      name 'Facebook for Dummies'
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
    startup  { single_instances[:startup] }
    factory :user2 do
      email 'bananas@tropical.com'
      name 'Tropical Bananas'
      startup  { single_instances[:startup] }
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
      start_video_url 'http://www.youtube.com/watch?v=4vkqBfv8OMM'
      factory :completed_checkin do
        end_video_url 'http://www.youtube.com/watch?v=4vkqaZv8OMM'
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
end