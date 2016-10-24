FactoryGirl.define do
  factory :project_transfer_user do
    association :to_user, factory: :user

    trait :with_project_transfer do
      project_transfer
    end
  end
end
