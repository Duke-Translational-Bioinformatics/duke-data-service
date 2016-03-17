FactoryGirl.define do
  factory :file_version do
    data_file
    version { SecureRandom.random_number(20) }
    label { Faker::Hacker.say_something_smart }
    is_deleted false
    association :upload, :completed

    trait :deleted do
      is_deleted true
    end

    trait :invalid do
      to_create {|instance| instance.save(validate: false) }
      creator { nil }
    end
  end
end
