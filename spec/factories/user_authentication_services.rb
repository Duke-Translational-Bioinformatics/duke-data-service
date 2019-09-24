FactoryBot.define do
  factory :user_authentication_service do
    sequence(:uid) { |n| "#{ Faker::Internet.user_name(separators: ['_']) }_#{n}" }

    trait :populated do
      user
      association :authentication_service, factory: :duke_authentication_service
    end
  end
end
