# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :rating do
    investor_id 1
    startup_id 1
    interested false
    feedback 1
    explanation "MyText"
  end
end
