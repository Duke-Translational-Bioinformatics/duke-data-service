FactoryGirl.define do
  factory :chunk do
    upload
    number { Faker::Number.digit }
    size { Faker::Number.digit }
    fingerprint_value { SecureRandom.hex(32) }
    fingerprint_algorithm "md5"

    trait :swift do
      upload { create(:upload, :swift) }
    end
  end
end
