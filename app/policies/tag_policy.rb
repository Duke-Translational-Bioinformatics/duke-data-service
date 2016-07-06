class TagPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    permission :update_file
  end

  def update?
    permission :update_file
  end

  def destroy?
    permission :update_file
  end

  class Scope < Scope
    def resolve
      tag_scope = scope.none
      Tag.taggable_classes.each do |taggable_class|
        tag_scope = tag_scope.union(
          Tag.where(
            taggable_type: taggable_class.base_class, 
            taggable_id: policy_scope(taggable_class).select(:id).unscope(:order)
          )
        )
      end
      tag_scope
    end
  end
end
