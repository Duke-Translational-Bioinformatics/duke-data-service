FactoryGirl.define do
  factory :associated_with_user_prov_relation do
    association :creator, factory: :user
    is_deleted false
    association :relatable_from, factory: :user
    relationship_type { 'was-associated-with' }
    association :relatable_to, factory: :activity
    skip_graphing { true }

    trait :graphed do
      skip_graphing { false }
      association :creator, factory: [:user, :graphed]
      association :relatable_from, factory: [:user, :graphed]
      association :relatable_to, factory: [:activity, :graphed]
    end
  end
end
