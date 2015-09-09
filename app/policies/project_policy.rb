class ProjectPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    scope.where(:id => record.id).exists?
  end

  def destroy?
    scope.where(:id => record.id).exists?
  end

  class Scope < Scope
    def resolve
      scope.joins(:project_permissions).where(project_permissions: {user: user})
    end
  end
end
