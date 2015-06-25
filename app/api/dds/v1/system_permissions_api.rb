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

      desc 'Grant system permissions to user' do
        detail 'Sets the auth_roles for a given user'
        named 'grant permissions'
        failure [401]
      end
      params do
        optional :auth_roles
      end
      put '/system/permissions/:user_id', root: false do
        user_params = declared(params, include_missing: false)
        user = User.find(params[:user_id])
        if user.update(auth_roles: user_params[:auth_roles])
          {
            user: UserSerializer.new(user),
            auth_roles: user.auth_roles.collect {|r| AuthRoleSerializer.new(r)}
          }
        else
          error!({
            error: 400, 
            reason: 'validation failed', 
            errors: []
          }, 400)
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
