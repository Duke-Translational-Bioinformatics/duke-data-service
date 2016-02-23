FactoryGirl.define do
  factory :user_api_secret do
    key { SecureRandom.hex }

    trait :populated do
      user
    end
  end
end
