module DDS
  module V1
    class ProjectAffiliatesAPI < Grape::API
      desc 'Associate affiliate to a project' do
        detail 'Deletes any existing project role for the user and assigns new role.'
        named 'create project affiliation'
        failure [
          {code: 200, message: 'Success'},
          {code: 400, message: 'Project Name Already Exists'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project Does not Exist'}
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
        project = hide_logically_deleted Project.find(params[:project_id])
        user = User.find(params[:user_id])
        affiliation = project.affiliations.where(user: user).first ||
          project.affiliations.build({
            user: user
          })
        affiliation.project_role_id = declared_params[:project_role][:id]
        authorize affiliation, :create?
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
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project Does not Exist'}
        ]
      end
      get '/projects/:project_id/affiliates', adapter: :json, root: 'results' do
        authenticate!
        project = hide_logically_deleted Project.find(params[:project_id])
        authorize Affiliation.new(project: project), :index?
        policy_scope(project.affiliations)
      end

      desc 'View project level affiliation for a user' do
        detail 'View project level affiliation for a user'
        named 'get project affiliation'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project Does not Exist'}
        ]
      end
      get '/projects/:project_id/affiliates/:user_id', root: false do
        authenticate!
        project = hide_logically_deleted Project.find(params[:project_id])
        user = User.find(params[:user_id])
        affiliation = Affiliation.where(project: project, user: user).first
        authorize affiliation, :show?
        affiliation
      end

      desc 'Delete project affiliation' do
        detail 'Remove project level affiliation for a user'
        named 'delete project affiliation'
        failure [
          {code: 204, message: 'Successfully Deleted'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project Does not Exist'}
        ]
      end
      delete '/projects/:project_id/affiliates/:user_id', root: false do
        authenticate!
        project = hide_logically_deleted Project.find(params[:project_id])
        user = User.find(params[:user_id])
        affiliations = Affiliation.where(project: project, user: user).all
        authorize affiliations.first, :destroy?
        affiliations.each do |affiliation|
          affiliation.destroy
        end
        body false
      end
    end
  end
end
