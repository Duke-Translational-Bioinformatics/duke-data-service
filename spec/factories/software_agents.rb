FactoryGirl.define do
  factory :software_agent do
    name { "#{Faker::Team.name}_#{rand(10**3)}" }
    description { Faker::Hacker.say_something_smart }
    repo_url { Faker::Internet.url }
    association :creator, factory: :user
    skip_graphing { true }

    trait :graphed do
      skip_graphing { false }
    end

    trait :deleted do
      is_deleted true
    end

    trait :with_key do
      api_key
    end
  end
end
