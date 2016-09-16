FactoryGirl.define do
  factory :template do
    sequence(:name) { |n| "#{Faker::Name.first_name}_#{n}" }
    label { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    association :creator, factory: :user
    is_deprecated false
  end
end
