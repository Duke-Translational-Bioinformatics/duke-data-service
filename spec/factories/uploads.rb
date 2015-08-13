FactoryGirl.define do
  factory :upload do
    project_id { SecureRandom.uuid }
    name { Faker::Internet.slug }
    content_type "text/plain"
    size { Faker::Number.number(2) }
    fingerprint_value { SecureRandom.hex(32) }
    fingerprint_algorithm "md5"
    storage_provider_id { Faker::Number.number(2) }
  end

end
