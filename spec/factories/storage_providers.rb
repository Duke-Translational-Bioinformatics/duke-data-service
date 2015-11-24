FactoryGirl.define do
  factory :storage_provider do
    name { Faker::Name.name }
    display_name { Faker::Name.name }
    description { Faker::Company.catch_phrase }
    url_root { Faker::Internet.domain_name }
    provider_version { Faker::App.version }
    auth_uri { Faker::Internet.url }
    service_user { Faker::Internet.user_name }
    service_pass { Faker::Internet.password }
    primary_key { SecureRandom.hex }
    secondary_key { SecureRandom.hex }

    trait :swift do
      name { ENV['SWIFT_ACCT'] || Faker::Name.name }
      display_name { ENV['SWIFT_DISPLAY_NAME'] || Faker::Name.name }
      description { ENV['SWIFT_DESCRIPTION'] || Faker::Company.catch_phrase }
      url_root { ENV['SWIFT_URL_ROOT'] || 'http://192.168.99.100:12345' }
      provider_version { ENV['SWIFT_VERSION'] || Faker::App.version }
      auth_uri { ENV['SWIFT_AUTH_URI'] || '/auth/v1.0' }
      service_user { ENV["SWIFT_USER"] || Faker::Internet.user_name }
      service_pass { ENV['SWIFT_PASS'] || Faker::Internet.password }
    end

    trait :swift_env do
      name { ENV['SWIFT_ACCT'] }
      display_name { ENV['SWIFT_DISPLAY_NAME'] }
      description { ENV['SWIFT_DESCRIPTION'] }
      url_root { ENV['SWIFT_URL_ROOT'] }
      provider_version { ENV['SWIFT_VERSION'] }
      auth_uri { ENV['SWIFT_AUTH_URI'] }
      service_user { ENV["SWIFT_USER"] }
      service_pass { ENV['SWIFT_PASS'] }
      primary_key { ENV['SWIFT_PRIMARY_KEY'] }
      secondary_key { ENV['SWIFT_SECONDARY_KEY'] }
    end
  end
end
