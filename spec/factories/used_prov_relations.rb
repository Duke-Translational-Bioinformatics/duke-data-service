FactoryBot.define do
  factory :used_prov_relation do
    association :creator, factory: :user
    is_deleted { false }
    association :relatable_from, factory: :activity
    association :relatable_to, factory: :file_version
  end
end
