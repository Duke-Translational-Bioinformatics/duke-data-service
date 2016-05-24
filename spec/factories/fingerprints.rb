FactoryGirl.define do
  factory :fingerprint do
    algorithm "md5"
    value { SecureRandom.hex(32) }
  end
end
