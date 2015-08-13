FactoryGirl.define do
  factory :chunk do
    upload_id { SecureRandom.uuid }
    number 1
    size 1
    fingerprint_value { SecureRandom.hex(32) }
    fingerprint_algorithm "md5"
  end
end
