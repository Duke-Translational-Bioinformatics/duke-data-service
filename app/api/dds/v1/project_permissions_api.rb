module DDS
  module V1
    class ProjectPermissionsAPI < Grape::API
      desc 'List project level permissions' do
        detail 'Lists project permissions.'
        named 'list project permissions'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project Does not Exist'}
        ]
      end
      get '/projects/:project_id/permissions', adapter: :json, root: 'results' do
        authenticate!
        project = hide_logically_deleted Project.find(params[:project_id])
        authorize ProjectPermission.new(project: project), :index?
        policy_scope(ProjectPermission).where(project: project)
      end

      desc 'Grant project level permissions to a user' do
        detail 'Revokes (deletes) any existing project level authorization roles for the user and grants new set.'
        named 'grant project permissions'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project, User, or AuthRole Does not Exist'}
        ]
      end
      params do
        requires :auth_role, desc: "AuthRole object", type: Hash do
          requires :id, type: String
        end
      end
      put '/projects/:project_id/permissions/:user_id', root: false do
        authenticate!
        permission_params = declared(params)
        project = hide_logically_deleted Project.find(params[:project_id])
        user = User.find(params[:user_id])
        if permission = ProjectPermission.find_by(project: project, user: user)
          authorize permission, :update?
        else
          permission = ProjectPermission.new(project: project, user: user)
          authorize permission, :create?
        end

        permission.auth_role = AuthRole.find(permission_params[:auth_role][:id])
        unless permission.auth_role
          raise ActiveRecord::RecordNotFound.new(message: "Couldn't find AuthRole with id #{permission_params[:auth_role][:id]}")
        end

        if permission.save
          permission
        else
          validation_error! permission
        end
      end

      desc 'View project level permissions for a user' do
        detail 'View project permissions.'
        named 'view project permissions'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project or User Does not Exist'}
        ]
      end
      get '/projects/:project_id/permissions/:user_id', root: false do
        authenticate!
        project = hide_logically_deleted Project.find(params[:project_id])
        user = User.find(params[:user_id])
        permission = ProjectPermission.find_by(project: project, user: user)
        unless permission
          raise ActiveRecord::RecordNotFound.new(message: "Couldn't find ProjectPermission with project_id #{params[:project_id]} user #{params[:user_id]}")
        end
        authorize permission, :show?
        permission
      end

      desc 'Revoke project level permissions for user' do
        detail 'Revoke project permissions'
        named 'revoke project permissions'
        failure [
          {code: 200, message: 'This will never happen'},
          {code: 204, message: 'Successfully Deleted'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project or User Does not Exist'}
        ]
      end
      delete '/projects/:project_id/permissions/:user_id', root: false do
        authenticate!
        project = hide_logically_deleted Project.find(params[:project_id])
        user = User.find(params[:user_id])
        permission = ProjectPermission.find_by!(project: project, user: user)
        authorize permission, :destroy?
        permission.destroy
        body false
      end
    end
  end
end
