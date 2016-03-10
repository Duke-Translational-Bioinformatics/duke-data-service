class AffiliationPolicy < ApplicationPolicy
  def show?
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
end
