class ChunkPolicy < ApplicationPolicy
  def show?
    permission :create_file
  end

  def create?
    permission :create_file
  end

  def update?
    permission :create_file
  end

  def destroy?
    permission :create_file
  end

  class Scope < Scope
    def resolve
      super :create_file
    end
  end
end
