FactoryGirl.define do
  factory :user do
    uuid { SecureRandom.uuid }
    etag { SecureRandom.hex }
    email { Faker::Internet.email }
    name { Faker::Name.name }

    trait :with_auth_role do
      auth_role_ids [FactoryGirl.create(:auth_role).text_id]
    end
  end
end
