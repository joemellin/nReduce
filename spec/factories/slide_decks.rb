# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :slide_deck do
    startup_id 1
    slides "MyText"
    title "MyString"
  end
end
