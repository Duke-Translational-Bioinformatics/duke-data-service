module DDS
  module V1
    class ProjectsAPI < Grape::API
      helpers PaginationParams

      desc 'Create a project' do
        detail 'Creates a project for the given payload.'
        named 'create project'
        failure [
          {code: 200, message: 'This will never actually happen'},
          {code: 202, message: 'Accepted, subject to further processing'},
          {code: 400, message: 'Project Name Already Exists'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Project Does not Exist'}
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
        if project.save
          status 202
          project
        else
          validation_error!(project)
        end
      end

      desc 'List projects' do
        detail 'Lists projects for which the current user has the "view_project" permission.'
        named 'list projects'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'}
        ]
      end
      params do
        use :pagination
      end
      get '/projects', adapter: :json, root: 'results' do
        authenticate!
        authorize Project.new, :index?
        paginate(policy_scope(Project).where(is_deleted: false))
      end

      desc 'View project details' do
        detail 'Returns the project details for a given project uuid.'
        named 'view project'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden'},
          {code: 404, message: 'Project Does not Exist'}
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
          {code: 200, message: 'Success'},
          {code: 400, message: 'Project Name Already Exists'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden'},
          {code: 404, message: 'Project Does not Exist'}
        ]
      end
      params do
        requires :id, type: String, desc: 'Project UUID'
        optional :name, type: String, desc: 'The Name of the Project'
        optional :description, type: String, desc: 'The Description of the Project'
      end
      put '/projects/:id', root: false do
        authenticate!
        project_params = declared(params, {include_missing: false}, [:name, :description])
        project = hide_logically_deleted Project.find(params[:id])
        authorize project, :update?
        if project.update(project_params.merge(etag: SecureRandom.hex))
          project
        else
          validation_error!(project)
        end
      end

      desc 'Delete a project' do
        detail 'Marks a project as being deleted.'
        named 'delete project'
        failure [
          {code: 204, message: 'Successfully Deleted'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden'},
          {code: 404, message: 'Project Does not Exist'}
        ]
      end
      params do
        requires :id, type: String, desc: 'Project UUID'
      end
      delete '/projects/:id', root: false do
        authenticate!
        project = hide_logically_deleted Project.find(params[:id])
        authorize project, :destroy?
        project.update(is_deleted: true)
        body false
      end
    end
  end
end
