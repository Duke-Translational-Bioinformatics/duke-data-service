class DataFilePolicy < ApplicationPolicy
  def download?
    permission
  end

  def move?
    permission
  end

  def rename?
    permission
  end

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
