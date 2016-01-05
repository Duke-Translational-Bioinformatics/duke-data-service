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
          etag: SecureRandom.hex,
          name: project_params[:name],
          description: project_params[:description],
          creator_id: current_user.id,
        })
        Audited.audit_class.as_user(current_user) do
          if project.save
            pre_permission_audit = project.audits.last
            last_permission = project.set_project_admin
            post_permission_audit = project.audits.last
            last_permission_audit = last_permission.audits.last
            annotate_audits [pre_permission_audit, post_permission_audit, last_permission_audit]
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
      params do
        requires :id, type: String, desc: 'Project UUID'
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
        requires :id, type: String, desc: 'Project UUID'
        optional :name, type: String, desc: 'The Name of the Project'
        optional :description, type: String, desc: 'The Description of the Project'
      end
      put '/projects/:id', root: false do
        authenticate!
        project_params = declared(params, include_missing: false)
        project = hide_logically_deleted Project.find(params[:id])
        authorize project, :update?
        Audited.audit_class.as_user(current_user) do
          if project.update(project_params.merge(etag: SecureRandom.hex))
            annotate_audits [project.audits.last]
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
      params do
        requires :id, type: String, desc: 'Project UUID'
      end
      delete '/projects/:id', root: false do
        authenticate!
        project = hide_logically_deleted Project.find(params[:id])
        authorize project, :destroy?
        Audited.audit_class.as_user(current_user) do
          project.update(is_deleted: true)
          annotate_audits [project.audits.last]
        end
        body false
      end
    end
  end
end
