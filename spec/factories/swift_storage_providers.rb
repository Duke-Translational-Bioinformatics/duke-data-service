FactoryBot.define do
  factory :swift_storage_provider do
    name { ENV['SWIFT_ACCT'] || Faker::Name.name }
    sequence(:display_name) { |n| ENV['SWIFT_DISPLAY_NAME'] || "#{Faker::Name.name}_#{n}" }
    description { ENV['SWIFT_DESCRIPTION'] || Faker::Company.catch_phrase }
    url_root { ENV['SWIFT_URL_ROOT'] || 'http://swift.local:12345' }
    provider_version { ENV['SWIFT_VERSION'] || Faker::App.version }
    auth_uri { ENV['SWIFT_AUTH_URI'] || '/auth/v1.0' }
    service_user { ENV["SWIFT_USER"] || Faker::Internet.user_name }
    service_pass { ENV['SWIFT_PASS'] || Faker::Internet.password }
    primary_key { SecureRandom.hex }
    secondary_key { SecureRandom.hex }
    chunk_hash_algorithm { ENV['SWIFT_CHUNK_HASH_ALGORITHM'] || Faker::Hacker.abbreviation }
    chunk_max_number { ENV['SWIFT_CHUNK_MAX_NUMBER'] || Faker::Number.between(100,1000) }
    chunk_max_size_bytes { ENV['SWIFT_CHUNK_MAX_SIZE_BYTES'] || Faker::Number.between(4368709122, 6368709122) }

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
