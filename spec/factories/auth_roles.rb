FactoryGirl.define do
  factory :auth_role do
    text_id { Faker::Internet.slug }
    name { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    permissions { (0..Faker::Number.digit.to_i).collect { Faker::Internet.slug } }
    contexts  { (0..Faker::Number.digit.to_i).collect { Faker::Internet.slug } }
    is_deprecated false

    trait :deprecated do
      is_deprecated true
    end
  end

end
