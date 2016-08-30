class TemplatePolicy < ApplicationPolicy
  def show?
    true
  end

  def create?
    creator? || system_permission
  end

  def update?
    creator? || system_permission
  end

  def destroy?
    creator? || system_permission
  end

  class Scope < Scope
    def resolve
      scope
    end
  end

  private

  def creator?
    record.creator == user
  end
end
