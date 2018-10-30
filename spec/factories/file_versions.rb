FactoryBot.define do
  factory :file_version do
    data_file
    label { Faker::Hacker.say_something_smart }
    is_deleted false
    is_purged false
    association :upload, :completed, :skip_validation

    trait :deleted do
      is_deleted true
    end

    trait :purged do
      is_deleted true
      is_purged true
    end

    trait :invalid do
      to_create {|instance| instance.save(validate: false) }
      creator { nil }
    end
  end
end
