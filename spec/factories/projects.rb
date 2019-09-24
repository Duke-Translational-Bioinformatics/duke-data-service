FactoryBot.define do
  factory :project do
    sequence(:name) { |n| "#{Faker::Team.name}_#{n}" }
    description { Faker::Hacker.say_something_smart }
    association :creator, factory: :user
    etag { SecureRandom.hex }
    is_consistent { true }

    trait :deleted do
      is_deleted { true }
    end

    trait :invalid do
      to_create {|instance| instance.save(validate: false) }
      description { nil }
    end

    trait :inconsistent do
      is_consistent { false }
    end

    trait :with_slug do
      slug { Faker::Internet.slug(words: nil, glue: '_') }
    end
  end
end
