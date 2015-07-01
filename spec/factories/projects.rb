FactoryGirl.define do
  factory :project do
    name { Faker::Team.name }
    description { Faker::Hacker.say_something_smart }
    uuid { SecureRandom.uuid }
    creator_id { Faker::Number.number(8) }
    etag { SecureRandom.hex }
    is_deleted false

    trait :deleted do
      is_deleted true
      deleted_at { Time.now }
    end
  end

end
