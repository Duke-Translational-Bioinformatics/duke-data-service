FactoryGirl.define do
  factory :system_permission do
    user
    association :auth_role, factory: [:auth_role, :system]
  end
end
