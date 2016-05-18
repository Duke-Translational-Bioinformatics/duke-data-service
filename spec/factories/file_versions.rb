FactoryGirl.define do
  factory :file_version do
    data_file
    label { Faker::Hacker.say_something_smart }
    is_deleted false
    association :upload, :completed
    skip_graphing { true }

    trait :graphed do
      skip_graphing { false }
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
