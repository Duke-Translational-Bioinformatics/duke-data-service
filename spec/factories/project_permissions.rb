FactoryGirl.define do
  factory :project_permission do
    project
    user
    auth_role
  end
end
