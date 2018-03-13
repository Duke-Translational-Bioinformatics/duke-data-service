class DataFilePolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def download?
    permission :download_file
  end

  def move?
    permission :create_file
  end

  def restore?
    permission :create_file
  end

  def rename?
    permission :update_file
  end

  def create?
    system_permission || (project_permission(:create_file) && record.upload.creator == user)
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
