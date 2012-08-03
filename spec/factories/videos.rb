# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :video do
    user_id 1
    external_id "MyString"
    video_type 1
    file_url "MyString"
    callback_result "MyText"
    vimeo_id 1
  end
end
