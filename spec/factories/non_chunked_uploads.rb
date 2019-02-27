FactoryBot.define do
  factory :non_chunked_upload do
    project
    sequence(:name) { |n| "#{Faker::Internet.slug(nil, '_')}_#{n}" }
    content_type { "text/plain" }
    size { Faker::Number.number(2) }
    etag { SecureRandom.hex }
    storage_provider
    association :creator, factory: :user
    is_consistent { true }

    trait :with_fingerprint do
      after(:build) do |upload, evaluator|
        fingerprint = build(:fingerprint, upload: upload)
        upload.association(:fingerprints).add_to_target(fingerprint)
      end
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
