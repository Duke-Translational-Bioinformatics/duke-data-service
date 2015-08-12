FactoryGirl.define do
  factory :folder do
    name { Faker::Team.name }
    parent_id { SecureRandom.uuid }
    project
    is_deleted false

    trait :root do
      parent_id nil
    end

    trait :deleted do
      is_deleted true
    end
  end
end
