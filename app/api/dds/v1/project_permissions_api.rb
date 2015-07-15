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
    end
  end
end
