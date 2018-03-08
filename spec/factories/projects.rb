FactoryBot.define do
  factory :project do
    name { "#{Faker::Team.name}_#{rand(10**3)}" }
    description { Faker::Hacker.say_something_smart }
    association :creator, factory: :user
    etag { SecureRandom.hex }
    is_consistent { true }

    trait :deleted do
      is_deleted true
    end

    trait :invalid do
      to_create {|instance| instance.save(validate: false) }
      description { nil }
    end

    trait :inconsistent do
      is_consistent { false }
    end
  end
end
