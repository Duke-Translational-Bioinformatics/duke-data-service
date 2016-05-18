FactoryGirl.define do
  factory :associated_with_software_agent_prov_relation do
    association :creator, factory: :user
    is_deleted false
    association :relatable_from, factory: :software_agent
    relationship_type { 'was-associated-with' }
    association :relatable_to, factory: :activity
    skip_graphing { true }

    trait :graphed do
      association :creator, factory: [:user, :graphed]
      association :relatable_from, factory: [:software_agent, :graphed]
      association :relatable_to, factory: [:activity, :graphed]
      skip_graphing { false }
    end
  end
end
