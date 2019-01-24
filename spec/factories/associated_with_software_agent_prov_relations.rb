FactoryBot.define do
  factory :associated_with_software_agent_prov_relation do
    association :creator, factory: :user
    is_deleted { false }
    association :relatable_from, factory: :software_agent
    association :relatable_to, factory: :activity
  end
end
