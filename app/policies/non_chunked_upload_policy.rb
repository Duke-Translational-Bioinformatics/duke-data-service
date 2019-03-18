class NonChunkedUploadPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    permission :create_file
  end

  def update?
    permission :update_file
  end

  def complete?
    permission :create_file
  end

  def destroy?
    system_permission
  end

  class Scope < Scope
    def resolve
      super :view_project
    end
  end
end
