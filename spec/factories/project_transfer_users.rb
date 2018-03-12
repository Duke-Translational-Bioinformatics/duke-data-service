FactoryBot.define do
  factory :project_transfer_user do
    association :to_user, factory: :user
  end
end
