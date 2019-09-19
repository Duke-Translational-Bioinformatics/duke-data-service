module DDS
  module V1
    class SystemPermissionsAPI < Grape::API
      desc 'List system permissions' do
        detail 'Returns a list of users with their associated auth_roles'
        named 'list permissions'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'}
        ]
      end
      get '/system/permissions', adapter: :json, root: 'results' do
        authenticate!
        authorize SystemPermission.new, :index?
        policy_scope(SystemPermission).all
      end

      desc 'Grant system level permission to user' do
        detail 'Creates or updates system permission for a given user'
        named 'grant permission'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'User or AuthRole Does not Exist'}
        ]
      end
      params do
        requires :auth_role, desc: "AuthRole object", type: Hash do
          requires :id, type: String
        end
      end
      put '/system/permissions/:user_id', root: false do
        authenticate!
        system_params = declared(params, include_missing: false)
        user = User.find(params[:user_id])
        permission = SystemPermission.find_by(user: user) ||
          SystemPermission.new(user: user)
        permission.auth_role = AuthRole.find(system_params[:auth_role][:id])
        authorize permission, :create?
        if permission.save
          permission
        else
          validation_error! permission
        end
      end

      desc 'View system level permissions for user' do
        detail 'Returns the system permissions for a given user'
        named 'show permissions'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'User Does not Exist'}
        ]
      end
      get '/system/permissions/:user_id', root: false do
        authenticate!
        user = User.find(params[:user_id])
        permission = user.system_permission ||
          SystemPermission.new(user: user)
        authorize permission, :show?
        SystemPermission.find_by!(user: user)
      end

      desc 'Revoke system permissions to user' do
        detail 'Deletes system permissions for a given user'
        named 'delete permissions'
        failure [
          {code: 204, message: 'Successfully Deleted'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'User Does not Exist'}
        ]
      end
      delete '/system/permissions/:user_id', root: false do
        authenticate!
        user = User.find(params[:user_id])
        permission = SystemPermission.find_by!(user: user)
        authorize permission, :destroy?
        permission.destroy
        body false
      end
    end
  end
end
