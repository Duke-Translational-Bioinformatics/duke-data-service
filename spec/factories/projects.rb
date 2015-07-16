FactoryGirl.define do
  factory :project do
    id { SecureRandom.uuid }
    name { Faker::Team.name }
    description { Faker::Hacker.say_something_smart }
    creator_id { SecureRandom.uuid }
    etag { SecureRandom.hex }
    is_deleted false

    trait :deleted do
      is_deleted true
      deleted_at { Time.now }
    end
  end

end
