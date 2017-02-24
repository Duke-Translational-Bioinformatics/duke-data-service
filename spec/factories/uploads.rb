FactoryGirl.define do
  factory :upload do
    project
    name { "#{Faker::Team.name}_#{rand(10**3)}" }
    content_type "text/plain"
    size { Faker::Number.number(2) }
    etag { SecureRandom.hex }
    storage_provider
    association :creator, factory: :user

    trait :with_chunks do
      chunks { [ build(:chunk, number: 1) ] }
    end

    trait :with_fingerprint do
      fingerprints { [ build(:fingerprint) ] }
    end

    trait :swift do
      storage_provider { create(:storage_provider, :swift) }
    end

    trait :completed do
      completed_at { DateTime.now }
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
