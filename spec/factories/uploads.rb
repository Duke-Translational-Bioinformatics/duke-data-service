FactoryGirl.define do
  factory :upload do
    project
    name { Faker::Internet.slug }
    content_type "text/plain"
    size { Faker::Number.number(2) }
    fingerprint_value { SecureRandom.hex(32) }
    fingerprint_algorithm "md5"
    storage_provider

    trait :with_chunks do
      chunks { build_list(:chunk, 1) }
    end

    trait :swift do
      storage_provider { create(:storage_provider, :swift) }
    end
  end
end
