FactoryBot.define do
  factory :project_transfer do
    transient do
      to_user { create(:user) }
    end
    status_comment { Faker::Hacker.say_something_smart }
    project
    association :from_user, factory: :user

    trait :with_to_users do
      project_transfer_users { [ build(:project_transfer_user, to_user: to_user) ] }
    end

    trait :pending do
      status { 'pending' }
    end

    trait :accepted do
      status { 'accepted' }
    end

    trait :rejected do
      status { 'rejected' }
    end

    trait :canceled do
      status { 'canceled' }
    end

    trait :skip_validation do
      to_create {|instance| instance.save(validate: false) }
    end
  end
end
