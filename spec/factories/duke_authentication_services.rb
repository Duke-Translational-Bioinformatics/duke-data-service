FactoryGirl.define do
  factory :duke_authentication_service do
    service_id { SecureRandom.uuid }
    base_uri { Faker::Internet.url }
    name { Faker::Company.name }

    trait :default do
      is_default { true }
    end
  end
end
