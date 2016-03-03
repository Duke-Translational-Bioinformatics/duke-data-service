class SoftwareAgentPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    record.creator == user || system_permission
  end

  def show?
    true
  end


  def destroy?
    record.creator == user || system_permission
  end

  class Scope < Scope
    def resolve
      scope
    end
  end
end
