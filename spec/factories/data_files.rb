FactoryGirl.define do
  factory :data_file do
    name { Faker::Team.name }
    upload_id { SecureRandom.uuid }
    parent_id { SecureRandom.uuid }
    project_id { SecureRandom.uuid }
    creator_id { SecureRandom.uuid }
    is_deleted false

    factory :child_data_file do
      association :parent, factory: :folder
    end

    #Three children is an arbitrary number to test but keep # of children small
    factory :child_data_file_and_parent, parent: :folder do |folder|
      children { build_list :child_folder, 3 }
    end

    trait :root do
      parent_id nil
    end

    trait :deleted do
      is_deleted true
    end
  end
end
