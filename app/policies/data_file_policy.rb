class DataFilePolicy < ApplicationPolicy
  def download?
    permission.exists?
  end

  def move?
    permission.exists?
  end

  def rename?
    permission.exists?
  end

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
      scope.joins(:project_permissions).where(project_permissions: {user: user})
    end
  end
end
