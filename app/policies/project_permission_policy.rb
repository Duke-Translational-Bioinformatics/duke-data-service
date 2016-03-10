class ProjectPermissionPolicy < ApplicationPolicy
  def create?
    permission.exists?
  end

  def update?
    permission.exists? && record.user != user
  end

  def destroy?
    permission.exists? && record.user != user
  end

  class Scope < Scope
    def resolve
      scope.joins(project_permissions: :user).where(users: {id: user.id})
    end
  end
end
