FactoryBot.define do
  factory :project_role do
    sequence(:id) { |n| "#{Faker::Lorem.word}_#{n}" }
    name { Faker::Lorem.word.titleize }
    description { Faker::Lorem.sentence }

    trait :deprecated do
      is_deprecated true
    end
  end
end
