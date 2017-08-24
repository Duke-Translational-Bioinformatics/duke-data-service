class TagPolicy < ApplicationPolicy
  def show?
    Pundit::PolicyFinder.new(record.taggable).policy&.new(user, record.taggable)&.show?
  end

  def create?
    system_permission ||
      (record&.taggable&.respond_to?(:project_permissions) &&
                          project_permission(:update_file)) ||
      record&.taggable&.creator == user
  end

  def update?
    system_permission ||
      (record&.taggable&.respond_to?(:project_permissions) &&
                          project_permission(:update_file)) ||
      record&.taggable&.creator == user
  end

  def destroy?
    #Pundit::PolicyFinder.new(record.taggable).policy&.new(user, record.taggable)&.update?
    system_permission ||
      (record&.taggable&.respond_to?(:project_permissions) &&
                          project_permission(:update_file)) ||
      record&.taggable&.creator == user
  end

  class Scope < Scope
    def resolve
      tag_scope = scope.none
      Tag.taggable_classes.each do |taggable_class|
        tag_scope = tag_scope.union(
          Tag.where(
            taggable_type: taggable_class.base_class.to_s, 
            taggable_id: policy_scope(taggable_class).select(:id).unscope(:order)
          )
        )
      end
      tag_scope
    end
  end
end
