FactoryBot.define do
  factory :chunk do
    upload
    sequence(:number, 1000)
    size { Faker::Number.between(100, 1000) }
    fingerprint_value { SecureRandom.hex(32) }
    fingerprint_algorithm "md5"

    trait :swift do
      upload { create(:upload, :swift) }
    end
  end
end
