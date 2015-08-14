FactoryGirl.define do
  factory :storage_provider do
    name "MyString"
    url_root "MyString"
    provider_version "MyString"
    auth_uri "MyString"
    service_user "MyString"
    service_pass "MyString"
    primary_key "MyString"
    secondary_key "MyString"

    trait :swift_env do
      name { ENV['SWIFT_ACCT'] }
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
