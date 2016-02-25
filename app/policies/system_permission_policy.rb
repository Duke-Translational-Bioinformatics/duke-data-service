class SystemPermissionPolicy < ApplicationPolicy
  def create?
    permission.exists?
  end

  def update?
    permission.exists?
  end

  def destroy?
    permission.exists? && record.user != user
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
    scope
  end
end
