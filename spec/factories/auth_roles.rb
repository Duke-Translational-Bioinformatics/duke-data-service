FactoryGirl.define do
  factory :auth_role do
    id { "#{Faker::Internet.domain_word}_#{rand(10**3)}" }
    name { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    permissions { (0..Faker::Number.digit.to_i).collect { Faker::Internet.domain_word } }
    contexts  { (0..Faker::Number.digit.to_i).collect { Faker::Internet.slug } }
    is_deprecated false

    trait :system do
      contexts { ['system'] }
    end

    trait :deprecated do
      is_deprecated true
    end
  end

end
