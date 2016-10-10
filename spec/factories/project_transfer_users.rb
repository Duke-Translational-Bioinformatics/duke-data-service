FactoryGirl.define do
  factory :project_transfer_user do
    project_transfer
    association :to_user, factory: :user
  end
end
