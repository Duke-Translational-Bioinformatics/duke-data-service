FactoryBot.define do
  factory :data_file do
    transient do
      without_upload false
    end

    name { Faker::Team.name }
    label { Faker::Hacker.say_something_smart }
    parent_id { SecureRandom.uuid }
    project
    is_deleted false

    after(:build) do |f, evaluator|
      unless evaluator.without_upload
        f.upload = evaluator.upload || create(:upload, :swift, :completed, :with_fingerprint)
      end
    end

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

    trait :purged do
      is_deleted true
      is_purged true
    end

    trait :invalid do
      to_create {|instance| instance.save(validate: false) }
      name { nil }
    end
  end
end
