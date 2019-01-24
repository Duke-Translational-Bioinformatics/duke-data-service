FactoryBot.define do
  factory :activity do
    name { "#{Faker::Team.name}_#{rand(10**3)}" }
    description { Faker::Hacker.say_something_smart }
    association :creator, factory: :user

    trait :deleted do
      is_deleted { true }
    end
  end
end
