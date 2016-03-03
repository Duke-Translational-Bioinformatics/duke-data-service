class UploadPolicy < ApplicationPolicy
  def create?
    permission
  end

  def update?
    permission
  end

  def complete?
    permission
  end

  def destroy?
    permission
  end
end
