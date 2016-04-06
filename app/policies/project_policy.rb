class ProjectPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    true
  end

  def update?
    permission :update_project
  end

  def destroy?
    permission :delete_project
  end

  class Scope < Scope
    def resolve
      super :view_project
    end
  end
end
