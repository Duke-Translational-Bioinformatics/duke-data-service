FactoryBot.define do
  factory :upload do
    project
    sequence(:name) { |n| "#{Faker::Internet.slug(nil, '_')}_#{n}" }
    content_type "text/plain"
    size { Faker::Number.number(2) }
    etag { SecureRandom.hex }
    storage_provider
    association :creator, factory: :user
    is_consistent { true }

    trait :with_chunks do
      chunks { [ create(:chunk, :skip_validation, number: 1) ] }
    end

    trait :with_fingerprint do
      fingerprints { [ create(:fingerprint, :skip_validation) ] }
    end

    trait :completed do
      completed_at { DateTime.now }
    end

    trait :inconsistent do
      is_consistent { false }
    end

    trait :with_error do
      error_at { DateTime.now }
      error_message { Faker::Lorem.sentence }
    end

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
