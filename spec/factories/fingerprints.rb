FactoryBot.define do
  factory :fingerprint do
    upload { create(:upload, :skip_validation) }
    algorithm "md5"
    value { SecureRandom.hex(32) }

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
