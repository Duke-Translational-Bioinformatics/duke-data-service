class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    raise Pundit::NotAuthorizedError, "must be logged in" unless user
    @user = user
    @record = record
  end

  def index?
    show?
  end

  def show?
    permission
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve(auth_role_permission=nil)
      if user.system_permission
        scope
      else
        permission_scope = scope.joins(project_permissions: :auth_role).where(project_permissions: {user: user})
        if auth_role_permission
          permission_scope = permission_scope.merge(AuthRole.with_permission(auth_role_permission))
        end
        permission_scope
      end
    end

    def policy_scope(initial_scope)
      Pundit::PolicyFinder.new(initial_scope).scope!.new(user, initial_scope).resolve
    end
  end

  private

  def permission(auth_role_permission=nil)
    system_permission || project_permission(auth_role_permission)
  end

  def project_permission(auth_role_permission=nil)
    project_permissions = record.project_permissions.where(user: user)
    if auth_role_permission
      project_permissions = project_permissions.joins(:auth_role).merge(AuthRole.with_permission(auth_role_permission))
    end
    project_permissions.take
  end

  def system_permission
    user.system_permission
  end
end
