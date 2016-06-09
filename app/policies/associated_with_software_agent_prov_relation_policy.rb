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
    system_permission || record.creator_id == user.id
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        prov_relation_scope = scope.where(creator: user)
        prov_relation_scope = prov_relation_scope.union(
          AssociatedWithSoftwareAgentProvRelation.where(
            relatable_to_type: 'Activity',
            relatable_to_id: Activity.where(creator: user).select(:id).map {|a| a.id}
        ))
        prov_relation_scope
      end
    end
  end

  def permission
    system_permission ||
    record.relatable_to.creator_id == user.id
  end
end
