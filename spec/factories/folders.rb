FactoryBot.define do
  factory :folder do
    name { Faker::Team.name }
    project
    is_deleted { false }

    trait :with_parent do
      association :parent, factory: :folder
      project { parent.project }
    end

    trait :root do
      parent_id { nil }
    end

    trait :deleted do
      is_deleted { true }
    end

    trait :purged do
      is_deleted { true }
      is_purged { true }
    end
  end
end
