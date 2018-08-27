FactoryBot.define do
  factory :user do
    etag { SecureRandom.hex }
    sequence(:username) { |n| "#{Faker::Internet.user_name(nil, ['_'])}_#{n}" }
    email { Faker::Internet.email }
    display_name { Faker::Name.name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    last_login_at { Faker::Time.backward(14, :evening) }

    trait :delong do
      display_name 'Mark Randall DeLong'
      first_name 'Mark'
      last_name 'DeLong'
    end

    trait :with_key do
      api_key
    end

    trait :save_without_auditing do
      to_create {|instance| instance.save_without_auditing }
    end
  end
end
