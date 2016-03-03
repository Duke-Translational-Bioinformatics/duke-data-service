class DataFilePolicy < ApplicationPolicy
  def download?
    permission
  end

  def move?
    permission
  end

  def rename?
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
      if user.system_permission
        scope
      else
        scope.joins(:project_permissions).where(project_permissions: {user: user})
      end
    end
  end
end
