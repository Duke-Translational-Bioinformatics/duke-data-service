class UsedProvRelationPolicy < ApplicationPolicy
  def index?
    false
  end

  def update?
    false
  end

  def show?
    permission :view_project
  end

  def create?
    system_permission || (record.creator_id == user.id && permission(:view_project))
  end

  def destroy?
    system_permission || record.creator_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        scope.none
      end
    end
  end

  def permission(auth_role_permission=nil)
    system_permission || project_permission(auth_role_permission)
  end

  def project_permission(auth_role_permission=nil)
    project_permissions = record.relatable_to.project_permissions.where(user: user)
    if auth_role_permission
      project_permissions = project_permissions.joins(:auth_role).merge(AuthRole.with_permission(auth_role_permission))
    end
    project_permissions.take
  end
end
