class ApiKeyPolicy < ApplicationPolicy
  def index?
    false
  end

  def create?
    no_agents && (belongs_to_user || system_permission)
  end

  def update?
    no_agents && (belongs_to_user || system_permission)
  end

  def show?
    no_agents && (belongs_to_user || system_permission)
  end

  def destroy?
    no_agents && (belongs_to_user || system_permission)
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

  def belongs_to_user
    if record.software_agent_id
      record.software_agent.creator == user
    else
      record.user == user
    end
  end
end
