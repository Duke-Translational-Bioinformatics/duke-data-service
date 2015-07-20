FactoryGirl.define do
  factory :project do
    name { Faker::Team.name }
    description { Faker::Hacker.say_something_smart }
    creator_id { SecureRandom.uuid }
    etag { SecureRandom.hex }

    trait :deleted do
      is_deleted true
      deleted_at { Time.now }
    end
  end

end
