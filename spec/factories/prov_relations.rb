FactoryGirl.define do
  factory :prov_relation do
    association :creator, factory: :user
    is_deleted false

    factory :used_prov_relation do
      relationship_type { 'used' }
      association :relatable_from, factory: :activity
      association :relatable_to, factory: :file_version
    end
  end
end
