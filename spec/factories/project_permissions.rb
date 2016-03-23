FactoryGirl.define do
  factory :project_permission do
    transient do
      with_permissions false
      without_permissions false
    end

    project
    user
    auth_role {
      if with_permissions
        create(:auth_role, permissions: with_permissions)
      elsif without_permissions
        create(:auth_role, permissions: AuthRole.available_permissions - without_permissions)
      else
        create(:auth_role)
      end
    }

    trait :deleted do
      association :project, factory: [:project, :deleted]
    end
  end
end
