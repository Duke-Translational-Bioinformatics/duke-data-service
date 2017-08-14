class MetaTemplatePolicy < ApplicationPolicy
  def show?
    Pundit::PolicyFinder.new(record.templatable).policy&.new(user, record.templatable)&.show?
  end

  def create?
    system_permission ||
      (record&.templatable&.respond_to?(:project_permissions) &&
                          project_permission(:update_file)) ||
      record&.templatable&.creator == user
  end

  def update?
    system_permission ||
      (record&.templatable&.respond_to?(:project_permissions) &&
                          project_permission(:update_file)) ||
      record&.templatable&.creator == user
  end

  def destroy?
    system_permission ||
      (record&.templatable&.respond_to?(:project_permissions) &&
                          project_permission(:update_file)) ||
      record&.templatable&.creator == user
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
