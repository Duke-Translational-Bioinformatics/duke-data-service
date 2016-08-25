FactoryGirl.define do
  factory :template do
    name { Faker::Name.first }
    label { "#{Faker::App.name}_#{rand(10**3)}" }
    description { Faker::App.say_something_smart }
    is_deprecated false
  end
end
