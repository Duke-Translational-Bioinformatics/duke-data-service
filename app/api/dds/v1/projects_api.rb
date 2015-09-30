module DDS
  module V1
    class ProjectsAPI < Grape::API
      desc 'Create a project' do
        detail 'Creates a project for the given payload.'
        named 'create project'
        failure [
          [200, 'This will never actually happen'],
          [201, 'Created Successfully'],
          [400, 'Project Name Already Exists'],
          [401, 'Unauthorized'],
          [404, 'Project Does not Exist']
        ]
      end
      params do
        requires :name, type: String, desc: 'The Name of the Project'
        requires :description, type: String, desc: 'The Description of the Project'
      end
      post '/projects', root: false do
        authenticate!
        project_params = declared(params, include_missing: false)
        project = Project.new({
          id: SecureRandom.uuid,
          name: project_params[:name],
          description: project_params[:description],
          creator_id: current_user.id,
          audit_comment: '/api/v1/projects'
        })
        auditor = current_user
        Audited.audit_class.as_user(auditor) do
          if project.save
            project
          else
            validation_error!(project)
          end
        end
      end

      desc 'List projects' do
        detail 'Lists projects for which the current user has the "view_project" permission.'
        named 'list projects'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      get '/projects', root: 'results' do
        authenticate!
        policy_scope(Project).where(is_deleted: false)
      end

      desc 'View project details' do
        detail 'Returns the project details for a given project uuid.'
        named 'view project'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Project Does not Exist']
        ]
      end
      get '/projects/:id', root: false do
        authenticate!
        project = Project.find(params[:id])
        authorize project, :show?
        project
      end

      desc 'Update a project' do
        detail 'Update the project details for a given project uuid.'
        named 'update project'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [400, 'Project Name Already Exists'],
          [404, 'Project Does not Exist']
        ]
      end
      params do
        optional :name, type: String, desc: 'The Name of the Project'
        optional :description, type: String, desc: 'The Description of the Project'
      end
      put '/projects/:id', root: false do
        authenticate!
        project_params = declared(params, include_missing: false)
        project = Project.find(params[:id])
        authorize project, :update?
        auditor = current_user
        Audited.audit_class.as_user(auditor) do
          if project.update(project_params.merge(audit_comment: "/api/v1/projects/#{params[:id]}"))
            project
          else
            validation_error!(project)
          end
        end
      end

      desc 'Delete a project' do
        detail 'Marks a project as being deleted.'
        named 'delete project'
        failure [
          [204, 'Successfully Deleted'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Project Does not Exist']
        ]
      end
      delete '/projects/:id', root: false do
        authenticate!
        project = Project.find(params[:id])
        authorize project, :destroy?
        auditor = current_user
        Audited.audit_class.as_user(auditor) do
          project.update(is_deleted: true, audit_comment: "/api/v1/projects/#{params[:id]}")
        end
        body false
      end
    end
  end
end
