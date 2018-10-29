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

    trait :no_validations do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
