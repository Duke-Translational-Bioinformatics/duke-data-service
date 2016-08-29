FactoryGirl.define do
  factory :template do
    name { Faker::Name.first_name }
    label { "#{Faker::App.name}_#{rand(10**3)}" }
    description { Faker::Hacker.say_something_smart }
    association :creator, factory: :user
    is_deprecated false
  end
end
