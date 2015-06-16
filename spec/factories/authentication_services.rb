FactoryGirl.define do
  factory :authentication_service do
    uuid { SecureRandom.uuid }
    base_uri { Faker::Internet.url }
    name { Faker::Company.name }
  end
end
