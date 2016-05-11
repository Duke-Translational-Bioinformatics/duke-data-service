FactoryGirl.define do
  factory :associated_with_user_prov_relation do
    association :creator, factory: :user
    is_deleted false
    relationship_type { 'was-associated-with' }
    association :relatable_from, factory: :user
    association :relatable_to, factory: :activity
  end
end
