class ProjectPermissionPolicy < ApplicationPolicy
  def create?
    permission
  end

  def update?
    permission && record.user != user
  end

  def destroy?
    permission && record.user != user
  end

  class Scope < Scope
    def resolve
      scope.joins(project_permissions: :user).where(users: {id: user.id})
    end
  end
end
