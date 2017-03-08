FactoryGirl.define do
  factory :openid_authentication_service do
    service_id { SecureRandom.uuid }
    base_uri { Faker::Internet.url }
    login_initiation_uri { Faker::Internet.slug }
    login_response_type { 'token' }
    name { Faker::Company.name }
    client_id { SecureRandom.hex }
    client_secret { SecureRandom.hex }

    trait :default do
      is_default { true }
    end

    trait :deprecated do
      is_deprecated { true }
    end

    trait :from_auth_service_env do
      service_id { ENV['AUTH_SERVICE_SERVICE_ID'] }
      base_uri { ENV['AUTH_SERVICE_BASE_URI'] }
      name { ENV['AUTH_SERVICE_NAME'] }
      client_id { ENV['AUTH_SERVICE_CLIENT_ID'] }
      client_secret { ENV['AUTH_SERVICE_CLIENT_SECRET'] }
    end

    trait :openid_env do
      base_uri { ENV['OPENID_URL'] }
      client_id { ENV['OPENID_CLIENT_ID'] }
      client_secret { ENV['OPENID_CLIENT_SECRET'] }
    end

    trait :with_ldap_identity_provider do
      association :identity_provider, factory: :ldap_identity_provider
    end
  end
end
