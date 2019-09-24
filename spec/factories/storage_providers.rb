FactoryBot.define do
  factory :storage_provider do
    name { Faker::Name.name }
    sequence(:display_name) { |n| "#{Faker::Name.name}_#{n}" }
    description { Faker::Company.catch_phrase }
    is_default { !StorageProvider.where(is_default: true).any? }
    url_root { Faker::Internet.domain_name }
    provider_version { Faker::App.version }
    auth_uri { Faker::Internet.url }
    service_user { Faker::Internet.user_name }
    service_pass { Faker::Internet.password }
    primary_key { SecureRandom.hex }
    secondary_key { SecureRandom.hex }
    chunk_hash_algorithm { Faker::Hacker.abbreviation }
    chunk_max_number { Faker::Number.between(from: 100, to: 1000) }
    chunk_max_size_bytes { Faker::Number.between(from: 4368709122, to: 6368709122) }

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end

    trait :default do
      is_default { true }
    end
  end
end
