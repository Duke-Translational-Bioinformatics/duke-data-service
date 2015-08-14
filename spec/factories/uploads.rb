FactoryGirl.define do
  factory :upload do
    project
    name { Faker::Internet.slug }
    content_type "text/plain"
    size { Faker::Number.number(2) }
    fingerprint_value { SecureRandom.hex(32) }
    fingerprint_algorithm "md5"
    storage_provider
  end

end
