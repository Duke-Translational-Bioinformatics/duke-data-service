FactoryGirl.define do
  factory :project_role do
    id { Faker::Lorem.word }
    name { Faker::Lorem.word.titleize }
    description { Faker::Lorem.sentence }
    is_deprecated false

    trait :deprecated do
      is_deprecated true
    end
  end
end
