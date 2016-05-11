class TagPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    permission :update_file
  end

  def update?
    permission :update_file
  end

  def destroy?
    permission :update_file
  end

  class Scope < Scope
    def resolve(auth_role_permission=nil)
      if user.system_permission
        scope
      else
        # for now, dont use tag policy for scope
        scope.none
      end
    end
  end

  def permission(auth_role_permission=nil)
    super_user = system_permission
    return super_user if super_user

    case record.taggable.class.name
    when "DataFile"
      project_permission(auth_role_permission)
    else
      raise "#{record.taggable.class.name} is not supported"
    end
  end

  def project_permission(auth_role_permission=nil)
    project_permissions = record.taggable.project_permissions.where(user: user)
    if auth_role_permission
      project_permissions = project_permissions.joins(:auth_role).merge(AuthRole.with_permission(auth_role_permission))
    end
    project_permissions.take
  end

end
