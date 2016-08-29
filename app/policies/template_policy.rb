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
      if user.system_permission
        scope
      else
        scope.where(creator: user)
      end
    end
  end

  private

  def creator?
    record.creator == user
  end
end
