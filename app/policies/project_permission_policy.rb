class ProjectPermissionPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    permission :manage_project_permissions
  end

  def update?
    permission(:manage_project_permissions) &&
      (record.user != user || project_permission_siblings(:manage_project_permissions).count > 0)
  end

  def destroy?
    permission(:manage_project_permissions) &&
      (record.user != user || project_permission_siblings(:manage_project_permissions).count > 0)
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

  private

  def project_permission_siblings(auth_role_permission=nil)
    siblings = record.project_permissions.where.not(user: user)
    if auth_role_permission
      siblings = siblings.joins(:auth_role).merge(AuthRole.with_permission(auth_role_permission))
    end
    siblings
  end
end
