class SoftwareAgentPolicy < ApplicationPolicy
  def index?
    no_agents
  end

  def create?
    no_agents
  end

  def update?
    no_agents && (record.creator == user || system_permission)
  end

  def show?
    no_agents
  end

  def destroy?
    no_agents && (record.creator == user || system_permission)
  end

  class Scope < Scope
    def resolve
      if user.current_software_agent
        scope.none
      else
        scope
      end
    end
  end

  private
  def no_agents
    return !user.current_software_agent
  end
end
