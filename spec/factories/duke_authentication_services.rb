FactoryGirl.define do
  factory :duke_authentication_service do
    service_id { SecureRandom.uuid }
    base_uri { Faker::Internet.url }
    name { Faker::Company.name }

    trait :default do
      is_default { true }
    end

    trait :from_auth_service_env do
      service_id { ENV['AUTH_SERVICE_SERVICE_ID'] }
      base_uri { ENV['AUTH_SERVICE_BASE_URI'] }
      name { ENV['AUTH_SERVICE_NAME'] }
    end
  end
end
