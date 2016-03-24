FactoryGirl.define do
  factory :project_permission do
    project
    user
    auth_role 

    trait :project_admin do
      association :auth_role, factory: [:auth_role, :project_admin]
    end

    trait :deleted_project do
      association :project, factory: [:project, :deleted]
    end
  end
end
