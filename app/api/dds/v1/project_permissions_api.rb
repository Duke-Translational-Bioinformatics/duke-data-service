module DDS
  module V1
    class ProjectPermissionsAPI < Grape::API
      desc 'List project level permissions' do
        detail 'Lists project permissions.'
        named 'list project permissions'
        failure [401]
      end
      get '/projects/:project_id/permissions', root: false do
        authenticate!
        project = Project.where(uuid: params[:project_id]).first
        project.project_permissions
      end

      desc 'Grant project level permissions to a user' do
        detail 'Revokes (deletes) any existing project level authorization roles for the user and grants new set.'
        named 'grant project permissions'
        failure [401]
      end
      params do
        requires :auth_roles
      end
      put '/projects/:project_id/permissions/:user_id', root: false do
        authenticate!
        permission_params = declared(params)
        project = Project.where(uuid: params[:project_id]).first
        user = User.where(uuid: params[:user_id]).first
        permission = ProjectPermission.where(project: project, user: user).first || ProjectPermission.new(project: project, user: user)
        permission.attributes = permission_params
        if permission.save
          permission
        else
          validation_error! permission
        end
      end

      desc 'View project level permissions for a user' do
        detail 'View project permissions.'
        named 'view project permissions'
        failure [401]
      end
      get '/projects/:project_id/permissions/:user_id', root: false do
        authenticate!
        project = Project.where(uuid: params[:project_id]).first
        user = User.where(uuid: params[:user_id]).first
        ProjectPermission.where(project: project, user: user).first
      end

      desc 'Revoke project level permissions for user' do
        detail 'Revoke project permissions'
        named 'revoke project permissions'
        failure [401]
      end
      delete '/projects/:project_id/permissions/:user_id', root: false do
        authenticate!
        project = Project.where(uuid: params[:project_id]).first
        user = User.where(uuid: params[:user_id]).first
        ProjectPermission.where(project: project, user: user).first.destroy
        body false
      end
    end
  end
end
