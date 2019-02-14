FactoryBot.define do
  factory :software_agent do
    name { "#{Faker::Team.name}_#{rand(10**3)}" }
    description { Faker::Hacker.say_something_smart }
    repo_url { Faker::Internet.url }
    association :creator, factory: :user

    trait :deleted do
      is_deleted { true }
    end

    trait :with_key do
      api_key
    end

    trait :save_without_auditing do
      to_create {|instance| instance.save_without_auditing }
      association :creator, factory: [:user, :save_without_auditing]
    end
  end
end
