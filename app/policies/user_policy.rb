class UserPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def update?
    (record == user || system_permission)
  end

  def show?
    true
  end

  def destroy?
    (record == user || system_permission)
  end

  class Scope < Scope
    def resolve
      scope
    end
  end

  private
  def no_agents
    return !user.current_software_agent
  end
end
