class ChunkPolicy < ApplicationPolicy
  def create?
    permission
  end

  def update?
    permission
  end

  def destroy?
    permission
  end
end
