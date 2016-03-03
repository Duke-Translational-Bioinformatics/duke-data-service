class FolderPolicy < ApplicationPolicy
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
      if user.system_permission
        scope
      else
        scope.joins(:project_permissions).where(project_permissions: {user: user})
      end
    end
  end
end
