class ActivityPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    true
  end

  def show?
    system_permission || record.creator == user ||
    relatable_permission(:show?)
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
        activity_scope = scope.where(creator: user)
        activity_scope = activity_scope.union(
          Activity.joins(:used_prov_relations).where(prov_relations: {
            relatable_to_id: policy_scope(FileVersion.all)
          }
        ))
        activity_scope = activity_scope.union(
          Activity.joins(:generated_by_activity_prov_relations).where(prov_relations: {
            relatable_from_id: policy_scope(FileVersion.all)
          }
        ))
        activity_scope = activity_scope.union(
          Activity.joins(:invalidated_by_activity_prov_relations).where(prov_relations: {
            relatable_from_id: policy_scope(FileVersion.all)
          }
        ))
        activity_scope
      end
    end
  end

  private

  def relatable_permission(query)
    ProvRelation.where(relatable_from: record).each do |pr|
      return true if Pundit::PolicyFinder.new(pr).policy!.new(user, pr).public_send(query)
    end
    ProvRelation.where(relatable_to: record).each do |pr|
      return true if Pundit::PolicyFinder.new(pr).policy!.new(user, pr).public_send(query)
    end
    false
  end
end
