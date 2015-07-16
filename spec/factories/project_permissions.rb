FactoryGirl.define do
  factory :project_permission do
    project
    user
    auth_role_ids { [FactoryGirl.create(:auth_role).text_id] }
  end
end
