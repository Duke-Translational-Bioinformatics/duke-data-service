module DDS
  module V1
    class ProjectsAPI < Grape::API
      desc 'Create a project' do
        detail 'Creates a project for the given payload.'
        named 'create project'
        failure [401]
      end
      post '/projects', root: false do
        {}
      end

      desc 'List projects' do
        detail 'Lists projects for which the current user has the "view_project" permission.'
        named 'list projects'
        failure [401]
      end
      get '/projects', root: false do
        {}
      end

      desc 'View project details' do
        detail 'Returns the project details for a given project uuid.'
        named 'view project'
        failure [401]
      end
      get '/projects/:id', root: false do
        {}
      end

      desc 'Update a project' do
        detail 'Update the project details for a given project uuid.'
        named 'update project'
        failure [401]
      end
      put '/projects/:id', root: false do
        {}
      end

      desc 'Delete a project' do
        detail 'Marks a project as being deleted.'
        named 'delete project'
        failure [401]
      end
      delete '/projects/:id', root: false do
        body false
      end
    end
  end
end
