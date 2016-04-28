class ActivityPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def show?
    system_permission || permission
  end

  def update?
    system_permission || record.creator == user
  end

  def destroy?
    system_permission || record.creator == user
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        scope.where(creator_id: user.id)
      end
    end
  end

  private

  def permission
    record.creator == user
  end
end
