class MetaTemplatePolicy < ApplicationPolicy
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
      meta_template_scope = scope.none
      MetaTemplate.templatable_classes.each do |templatable_class|
        meta_template_scope = meta_template_scope.union(
          MetaTemplate.where(
            templatable_type: templatable_class.base_class.to_s,
            templatable_id: policy_scope(templatable_class).select(:id).unscope(:order)
          )
        )
      end
      meta_template_scope
    end
  end
end
