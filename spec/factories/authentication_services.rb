FactoryGirl.define do
  factory :authentication_service do
    base_uri { Faker::Internet.url }
    name { Faker::Company.name }
  end
end
