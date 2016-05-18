FactoryGirl.define do
  factory :used_prov_relation do
    association :creator, factory: :user
    is_deleted false
    relationship_type { 'used' }
    association :relatable_from, factory: :activity
    association :relatable_to, factory: :file_version
    skip_graphing { true }

    trait :graphed do
      skip_graphing { false }
      association :creator, factory: [:user, :graphed]
      association :relatable_from, factory: [:activity, :graphed]
      association :relatable_to, factory: [:file_version, :graphed]
    end
  end
end
