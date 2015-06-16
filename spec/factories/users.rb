FactoryGirl.define do
  factory :user do
    uuid { SecureRandom.uuid }
    etag { SecureRandom.hex }
    email { Faker::Internet.email }
    name { Faker::Name.name }
  end
end
