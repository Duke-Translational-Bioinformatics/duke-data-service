FactoryGirl.define do
  factory :permission do
    title { Faker::Internet.slug }
    description { Faker::Hacker.say_something_smart }
  end

end
