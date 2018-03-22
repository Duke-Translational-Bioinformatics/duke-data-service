FactoryBot.define do
  factory :meta_property do
    meta_template
    property
    value { Faker::Hacker.say_something_smart }
  end
end
