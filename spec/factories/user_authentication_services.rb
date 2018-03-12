FactoryBot.define do
  factory :user_authentication_service do
    uid { "#{Faker::Internet.user_name(nil, ['_'])}_#{Faker::Number.number(3) }" }

    trait :populated do
      user
      association :authentication_service, factory: :duke_authentication_service
    end
  end
end
