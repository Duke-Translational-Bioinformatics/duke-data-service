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
        Audited.audit_class.as_user(current_user) do
          affiliation = project.affiliations.where(user: user).first ||
            project.affiliations.build({
              user: user
            })
          affiliation.project_role_id = declared_params[:project_role][:id]
          affiliation.audit_comment = {action: request.env["REQUEST_URI"]}
          authorize affiliation, :create?
          if affiliation.save
            affiliation.audits.last.update(remote_address: request.ip)
            project.audits.last.update(remote_address: request.ip)
            affiliation
          else
            validation_error!(affiliation)
          end
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
      get '/projects/:project_id/affiliates', root: 'results' do
        authenticate!
        project = Project.find(params[:project_id])
        authorize project, :show?
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
        affiliation = Affiliation.where(project: project, user: user).first
        authorize affiliation, :show?
        affiliation
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
        affiliations = Affiliation.where(project: project, user: user).all
        authorize affiliations.first, :destroy?
        Audited.audit_class.as_user(current_user) do
          affiliations.each do |affiliation|
            affiliation.audit_comment = {action: request.env["REQUEST_URI"]}
            affiliation.destroy
            affiliation.audits.last.update(remote_address: request.ip)
            project.audits.last.update(remote_address: request.ip)
          end
        end
        body false
      end
    end
  end
end
