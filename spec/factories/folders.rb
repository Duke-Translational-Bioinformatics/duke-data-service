FactoryGirl.define do
  factory :folder do
    name { Faker::Team.name }
    folder_id { SecureRandom.uuid }
    project
    is_deleted false

    factory :child_folder do
      association :folder, factory: :folder
    end

    #Three children is an arbitrary number to test but keep # of children small
    factory :child_and_parent, parent: :folder do |folder|
      children { build_list :child_folder, 3 }
    end

    trait :root do
      folder_id nil
    end

    trait :deleted do
      is_deleted true
    end

  end
end
