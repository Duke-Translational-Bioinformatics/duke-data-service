FactoryBot.define do
  factory :generated_by_activity_prov_relation do
    association :creator, factory: :user
    is_deleted { false }
    association :relatable_from, factory: :file_version
    association :relatable_to, factory: :activity
  end
end
