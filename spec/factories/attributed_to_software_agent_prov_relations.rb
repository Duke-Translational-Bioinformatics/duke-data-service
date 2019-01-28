FactoryBot.define do
  factory :attributed_to_software_agent_prov_relation do
    association :creator, factory: :user
    is_deleted { false }
    association :relatable_from, factory: :file_version
    association :relatable_to, factory: :software_agent
  end
end
