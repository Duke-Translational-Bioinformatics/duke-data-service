class AffiliationPolicy < ApplicationPolicy
  def show?
    user.system_permission || permission
  end

  def create?
    user.system_permission || permission
  end

  def update?
    user.system_permission || permission
  end

  def destroy?
    user.system_permission || permission
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
