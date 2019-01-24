FactoryBot.define do
  factory :invalidated_by_activity_prov_relation do
    association :creator, factory: :user
    is_deleted { false }
    association :relatable_from, factory: [:file_version, :deleted]
    association :relatable_to, factory: :activity
  end
end
