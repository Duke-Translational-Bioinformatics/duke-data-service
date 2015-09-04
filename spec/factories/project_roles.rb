FactoryGirl.define do
  factory :project_role do
    id { Faker::Lorem.word }
    name { Faker::Lorem.word.titleize }
    description { Faker::Lorem.sentence }
    is_depricated false

    trait :depricated do
      is_depricated true
    end
  end
end
