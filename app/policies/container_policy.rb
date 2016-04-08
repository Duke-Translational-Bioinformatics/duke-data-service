class ContainerPolicy < ApplicationPolicy
  def show?
    permission :view_project
  end

  def download?
    false
  end

  def move?
    false
  end

  def rename?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  class Scope < Scope
    def resolve
      super :view_project
    end
  end
end
