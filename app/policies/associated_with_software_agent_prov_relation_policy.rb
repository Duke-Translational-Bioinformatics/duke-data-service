class AssociatedWithSoftwareAgentProvRelationPolicy < ApplicationPolicy
  def index?
    false
  end

  def update?
    false
  end

  def show?
    permission
  end

  def create?
    permission
  end

  def destroy?
    permission
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

  def permission
    system_permission ||
    record.relatable_to.creator_id == user.id
  end
end
