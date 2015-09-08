FactoryGirl.define do
  factory :user do
    etag { SecureRandom.hex }
    username { Faker::Internet.user_name }
    email { Faker::Internet.email }
    display_name { Faker::Name.name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    last_login_at { Faker::Time.backward(14, :evening) }

    trait :with_auth_role do
      auth_role_ids { [FactoryGirl.create(:auth_role).id] }
    end
  end
end
