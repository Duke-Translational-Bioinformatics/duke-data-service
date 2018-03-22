FactoryBot.define do
  factory :api_key do
    key { SecureRandom.hex }
  end
end
