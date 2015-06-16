FactoryGirl.define do
  factory :user_authentication_service do
    uid { "#{Faker::Name.first_name}_#{Faker::Number.number(3) }" }
    user
    authentication_service
  end
end
