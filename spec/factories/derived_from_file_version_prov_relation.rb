FactoryBot.define do
  factory :derived_from_file_version_prov_relation do
    association :creator, factory: :user
    is_deleted { false }
    association :relatable_from, factory: :file_version
    association :relatable_to, factory: :file_version
  end
end
