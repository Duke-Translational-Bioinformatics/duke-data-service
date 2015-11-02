FactoryGirl.define do
  factory :data_file do
    name { Faker::Team.name }
    upload_id { SecureRandom.uuid }
    parent_id { SecureRandom.uuid }
    project
    creator_id { SecureRandom.uuid }
    is_deleted false

    trait :with_parent do
      association :parent, factory: :folder
      project { parent.project }
    end

    trait :root do
      parent_id nil
    end

    trait :deleted do
      is_deleted true
    end
  end
end
