class ProjectPermissionPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    permission :manage_project_permissions
  end

  def update?
    permission(:manage_project_permissions) && record.user != user
  end

  def destroy?
    permission(:manage_project_permissions) && record.user != user
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        scope.joins(project_permissions: [:user, :auth_role]).where(users: {id: user.id}).where('auth_roles.permissions @> ?', [:view_project].to_json)
      end
    end
  end
end
