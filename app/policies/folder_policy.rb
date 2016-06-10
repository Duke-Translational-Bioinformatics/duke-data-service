class FolderPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def create?
    permission :create_file
  end

  def update?
    permission :create_file
  end

  def move?
    permission :create_file
  end

  def rename? 
    permission :create_file
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
