class GeneratedByActivityProvRelationPolicy < ApplicationPolicy
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
    system_permission ||
    (project_permission(:view_project) &&
     record.relatable_to.creator_id == user.id)
  end

  def destroy?
    system_permission || record.creator_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        prov_relation_scope = scope.where(creator: user)
        prov_relation_scope = prov_relation_scope.union(
          GeneratedByActivityProvRelation.where(
            relatable_from_id: policy_scope(FileVersion.all)
        ))
        prov_relation_scope = prov_relation_scope.union(
          GeneratedByActivityProvRelation.where(
            relatable_to_id: Activity.where(creator: user)
        ))
        prov_relation_scope
      end
    end
  end

  def permission(auth_role_permission=nil)
    system_permission || project_permission(auth_role_permission)
  end

  def project_permission(auth_role_permission=nil)
    project_permissions = record.relatable_from.project_permissions.where(user: user)
    if auth_role_permission
      project_permissions = project_permissions.joins(:auth_role).merge(AuthRole.with_permission(auth_role_permission))
    end
    project_permissions.take
  end
end
