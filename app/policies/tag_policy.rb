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
      data_file_scope = Pundit::PolicyFinder.new(DataFile).scope!.new(user, DataFile).resolve.select(:id).unscope(:order)
      scope.where(taggable_type: Container, taggable_id: data_file_scope)
    end
  end
end
