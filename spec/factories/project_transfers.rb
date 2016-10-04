FactoryGirl.define do
  factory :project_transfer do
    status_comment { Faker::Hacker.say_something_smart }
    project
    association :from_user, factory: :user

    trait :pending do
      status 'pending'
    end

    trait :accepted do
      status 'accepted'
    end

    trait :rejected do
      status 'rejected'
    end

    trait :canceled do
      status 'canceled'
    end
  end
end
