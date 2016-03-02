class UploadPolicy < ApplicationPolicy
  def create?
    permission
  end

  def update?
    permission
  end

  def complete?
    permission
  end

  def destroy?
    permission
  end

  class Scope < Scope
    def resolve
      scope.joins(:project_permissions).where(project_permissions: {user: user})
    end
  end
end
