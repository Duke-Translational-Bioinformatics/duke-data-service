class AffiliationPolicy < ApplicationPolicy
  def show?
    permission
  end

  def create?
    permission
  end

  def update?
    permission
  end

  def destroy?
    permission
  end

  class Scope < Scope
    def resolve
      if system_permission
        scope
      else
        scope.joins(:project_permissions).where(project_permissions: {user: user})
      end
    end
  end

  def permission
    system_permission || project_permission
  end
end
