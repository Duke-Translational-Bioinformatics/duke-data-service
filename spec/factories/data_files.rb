FactoryGirl.define do
  factory :data_file do
    name { Faker::Team.name }
    label { Faker::Hacker.say_something_smart }
    association :upload, :completed
    parent_id { SecureRandom.uuid }
    project
    creator { upload.creator }
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

    trait :invalid do
      to_create {|instance| instance.save(validate: false) }
      creator { nil }
    end
  end
end
