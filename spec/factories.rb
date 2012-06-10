FactoryGirl.define do
  factory :user do
    name 'Testy McTesterson'
    email 'testy@mctesterson.com'
    password 'please'
    password_confirmation 'please'
    location 'Buenos Aires, Argentina'
    skill_list 'rails, firebreathing'
  end

  factory :admin, class: User do
    name "Admin"
    admin true
  end

  factory :startup do
    name 'nReductionist'
  end
end