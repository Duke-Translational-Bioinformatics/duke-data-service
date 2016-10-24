FactoryGirl.define do
  factory :data_file do
    name { Faker::Team.name }
    label { Faker::Hacker.say_something_smart }
    association :upload, :completed, :with_fingerprint
    parent_id { SecureRandom.uuid }
    project
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
      name { nil }
    end
  end
end
