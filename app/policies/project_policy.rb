class ProjectPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    permission
  end

  def destroy?
    permission
  end
end
