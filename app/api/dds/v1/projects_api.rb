module DDS
  module V1
    class ProjectsAPI < Grape::API
      desc 'Create a project' do
        detail 'Creates a project for the given payload.'
        named 'create project'
        failure [400,401]
      end
      params do
        requires :name
        requires :description
        optional :pi_affiliate
      end
      post '/projects', root: false do
        authenticate!
        project_params = declared(params, include_missing: false)
        project = Project.new({
          uuid: SecureRandom.uuid,
          name: project_params[:name],
          description: project_params[:description],
          creator_id: current_user.id
        })
        if project.save
          project
        else
          validation_error!(project)
        end
      end

      desc 'List projects' do
        detail 'Lists projects for which the current user has the "view_project" permission.'
        named 'list projects'
        failure [401]
      end
      get '/projects', root: false do
        authenticate!
        Project.all
      end

      desc 'View project details' do
        detail 'Returns the project details for a given project uuid.'
        named 'view project'
        failure [401]
      end
      get '/projects/:id', root: false do
        authenticate!
        Project.where(uuid: params[:id]).first
      end

      desc 'Update a project' do
        detail 'Update the project details for a given project uuid.'
        named 'update project'
        failure [401]
      end
      params do
        optional :name
        optional :description
      end
      put '/projects/:id', root: false do
        authenticate!
        project_params = declared(params, include_missing: false)
        project = Project.where(uuid: params[:id]).first
        if project.update(project_params)
          project
        else
          validation_error!(project)
        end
      end

      desc 'Delete a project' do
        detail 'Marks a project as being deleted.'
        named 'delete project'
        failure [401]
      end
      delete '/projects/:id', root: false do
        authenticate!
        project = Project.where(:uuid => params[:id]).first
        project.update_attribute(:is_deleted, true)
        body false
      end
    end
  end
end
