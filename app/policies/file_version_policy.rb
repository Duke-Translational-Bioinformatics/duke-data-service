class FileVersionPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def download?
    permission :download_file
  end

  def create?
    permission :update_file
  end

  def update?
    permission :update_file
  end

  def destroy?
    permission :delete_file
  end

  class Scope < Scope
    def resolve
      super :view_project
    end
  end
end
