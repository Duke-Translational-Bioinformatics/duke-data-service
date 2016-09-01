FactoryGirl.define do
  factory :template do
    name { "#{Faker::Name.first_name}_#{rand(10**3)}" }
    label { Faker::App.name }
    description { Faker::Hacker.say_something_smart }
    association :creator, factory: :user
    is_deprecated false
  end
end
