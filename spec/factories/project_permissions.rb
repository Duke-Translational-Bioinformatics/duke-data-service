FactoryGirl.define do
  factory :project_permission do
    project
    user
    auth_role 

    trait :deleted_project do
      association :project, factory: [:project, :deleted]
    end
  end
end
