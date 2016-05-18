FactoryGirl.define do
  factory :attributed_to_software_agent_prov_relation do
    association :creator, factory: :user
    is_deleted false
    association :relatable_from, factory: :file_version
    relationship_type { 'was-attributed-to' }
    association :relatable_to, factory: :software_agent
    skip_graphing { true }

    trait :graphed do
      skip_graphing { false }
      association :creator, factory: [:user, :graphed]
      association :relatable_from, factory: [:file_version, :graphed]
      association :relatable_to, factory: [:software_agent, :graphed]
    end
  end
end
