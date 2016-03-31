class AffiliationPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    permission :update_project
  end

  def update?
    permission :update_project
  end

  def destroy?
    permission :update_project
  end

  class Scope < Scope
    def resolve
      super :view_project
    end
  end
end
