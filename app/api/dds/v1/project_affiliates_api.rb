module DDS
  module V1
    class ProjectAffiliatesAPI < Grape::API
      desc 'Associate affiliate to a project' do
        detail 'Deletes any existing project role for the user and assigns new role.'
        named 'create project affiliation'
        failure [
          [400, 'Project Name Already Exists'],
          [401, 'Unauthorized'],
          [404, 'Project Does not Exist']
        ]
      end
      params do
        requires :project_role, type: Hash do
          requires :id, type: String
        end
      end
      put '/projects/:project_id/affiliates/:user_id', root: false do
        authenticate!
        declared_params = declared(params, include_missing: false)
        project = Project.find(params[:project_id])
        user = User.find(params[:user_id])
        affiliation = project.affiliations.where(user: user).first ||
          project.affiliations.build({
            user: user,
          })
        affiliation.project_role_id = declared_params[:project_role][:id]
        if affiliation.save
          affiliation
        else
          validation_error!(affiliation)
        end
      end

      desc 'List project affiliations' do
        detail 'List project affiliations'
        named 'list project affiliation'
        failure [
          [401, 'Unauthorized'],
          [404, 'Project Does not Exist']
        ]
      end
      get '/projects/:project_id/affiliates', root: false do
        authenticate!
        project = Project.find(params[:project_id])
        project.affiliations
      end

      desc 'View project level affiliation for a user' do
        detail 'View project level affiliation for a user'
        named 'get project affiliation'
        failure [
          [401, 'Unauthorized'],
          [404, 'Project Does not Exist']
        ]
      end
      get '/projects/:project_id/affiliates/:user_id', root: false do
        authenticate!
        project = Project.find(params[:project_id])
        user = User.find(params[:user_id])
        Affiliation.where(project: project, user: user).first
      end

      desc 'Delete project affiliation' do
        detail 'Remove project level affiliation for a user'
        named 'delete project affiliation'
        failure [
          [401, 'Unauthorized'],
          [404, 'Project Does not Exist']
        ]
      end
      delete '/projects/:project_id/affiliates/:user_id', root: false do
        authenticate!
        project = Project.find(params[:project_id])
        user = User.find(params[:user_id])
        Affiliation.where(project: project, user: user).destroy_all
        body false
      end
    end
  end
end
