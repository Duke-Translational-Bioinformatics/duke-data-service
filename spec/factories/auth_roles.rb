FactoryGirl.define do
  factory :auth_role do
    id { Faker::Internet.domain_word }
    name { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    permissions { (0..Faker::Number.digit.to_i).collect { Faker::Internet.domain_word } }
    contexts  { (0..Faker::Number.digit.to_i).collect { Faker::Internet.slug } }
    is_deprecated false

    trait :deprecated do
      is_deprecated true
    end
  end

end
