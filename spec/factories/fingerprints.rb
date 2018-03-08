FactoryBot.define do
  factory :fingerprint do
    upload
    algorithm "md5"
    value { SecureRandom.hex(32) }
  end
end
