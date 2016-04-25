FactoryGirl.define do
  factory :activity do
    name { "#{Faker::Team.name}_#{rand(10**3)}" }
    description { Faker::Hacker.say_something_smart }
    started_on "2016-04-25 14:37:42"
    ended_on "2016-04-25 14:37:42"
    is_deleted false

    trait :deleted do
      is_deleted true
    end
  end
end
