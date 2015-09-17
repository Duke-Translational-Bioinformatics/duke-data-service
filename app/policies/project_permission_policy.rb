class ProjectPermissionPolicy < ApplicationPolicy
  def create?
    permission.exists?
  end

  def update?
    permission.exists?
  end

  def destroy?
    permission.exists?
  end

  class Scope < Scope
    def resolve
      scope.joins(project_permissions: :user).where(users: {id: user.id})
    end
  end
end
