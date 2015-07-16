FactoryGirl.define do
  factory :user do
    id { SecureRandom.uuid }
    etag { SecureRandom.hex }
    email { Faker::Internet.email }
    display_name { Faker::Name.name }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }

    trait :with_auth_role do
      auth_role_ids { [FactoryGirl.create(:auth_role).text_id] }
    end
  end
end
