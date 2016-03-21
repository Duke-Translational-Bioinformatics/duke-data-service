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
    system_permission || (project_permission && record.upload.creator == user)
  end

  def update?
    system_permission || (project_permission && record.upload.creator == user)
  end

  def destroy?
    permission
  end
end
