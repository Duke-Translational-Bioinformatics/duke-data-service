module DDS
  module V1
    class ProjectAffiliatesAPI < Grape::API
      desc 'Associate affiliate to a project' do
        detail 'Deletes any existing project role for the user and assigns new role.'
        named 'create project affiliation'
        failure [401]
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
    end
  end
end
