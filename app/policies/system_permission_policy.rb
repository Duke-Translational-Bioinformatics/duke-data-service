class SystemPermissionPolicy < ApplicationPolicy
  def create?
    permission
  end

  def update?
    permission
  end

  def destroy?
    permission && record.user != user
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        scope.none
      end
    end
  end

  private

  def permission
    scope.take
  end
end
