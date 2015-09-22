module DDS
  module V1
    class SystemPermissionsAPI < Grape::API
      desc 'List system permissions' do
        detail 'Returns a list of users with their associated auth_roles'
        named 'list permissions'
        failure [401]
      end
      get '/system/permissions', root: false do
        {
          results: User.all.collect {|u|
            {
              user: UserSerializer.new(u),
              auth_roles: u.auth_roles.collect {|r| AuthRoleSerializer.new(r)}
            }
          }
        }
      end

      desc 'Grant system level permission to user' do
        detail 'Creates or updates system permission for a given user'
        named 'grant permission'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [404, 'User or AuthRole Does not Exist']
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
          #validation_error! permission
        end
      end

      desc 'View system permissions to user' do
        detail 'Gets the auth_roles for a given user'
        named 'show permissions'
        failure [401]
      end
      get '/system/permissions/:user_id', root: false do
        user = User.find(params[:user_id])
        {
          user: UserSerializer.new(user),
          auth_roles: user.auth_roles.collect {|r| AuthRoleSerializer.new(r)}
        }
      end

      desc 'Revoke system permissions to user' do
        detail 'Deletes all auth_roles for a given user'
        named 'delete permissions'
        failure [401]
      end
      delete '/system/permissions/:user_id', root: false do
        user = User.find(params[:user_id])
        user.update_attribute(:auth_roles, nil)
        body false
      end
    end
  end
end
