class ProjectTransferPolicy < ApplicationPolicy
  def show?
    to_user? || from_user? || permission(:manage_project_permissions)
  end

  def index?
    to_user? || from_user? || permission(:manage_project_permissions)
  end

  def create?
    permission :manage_project_permissions
  end

  def update?
    to_user? || system_permission
  end

  def destroy?
    permission :manage_project_permissions
  end

  class Scope < Scope
    def resolve
      if user.system_permission
        scope
      else
        project_transfer_scope = super(:manage_project_permissions)
        project_transfer_scope = project_transfer_scope.union(
          ProjectTransfer.where(
            from_user: user
          ))
        project_transfer_scope = project_transfer_scope.union(
          ProjectTransfer.joins(project_transfer_users: [:to_user]).where(
            users: {id: user.id}
          ))
        project_transfer_scope
      end
    end
  end

  private

  def from_user?
    user == record.from_user
  end

  def to_user?
    record.to_users.include? user
  end

end
