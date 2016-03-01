class AffiliationPolicy < ApplicationPolicy
  def show?
    user.system_permission || permission.exists?
  end

  def create?
    user.system_permission || permission.exists?
  end

  def update?
    user.system_permission || permission.exists?
  end

  def destroy?
    user.system_permission || permission.exists?
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        scope.joins(:project_permissions).where(project_permissions: {user: user})
      end
    end
  end
end
