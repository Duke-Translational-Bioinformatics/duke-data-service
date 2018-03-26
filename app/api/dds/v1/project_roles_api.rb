module DDS
  module V1
    class ProjectRolesAPI < Grape::API
      namespace :project_roles do
        desc 'List project roles' do
          detail 'Lists project roles.'
          named 'list project roles'
          failure [
            {code: 200, message: 'Success'},
            {code: 401, message: 'Unauthorized'}
          ]
        end
        get '/', adapter: :json, root: 'results' do
          authenticate!
          ProjectRole.all
        end

        desc 'View project role details' do
          detail 'View project role details.'
          named 'view project role'
          failure [
            {code: 200, message: 'Success'},
            {code: 401, message: 'Unauthorized'},
            {code: 404, message: 'Unkown ProjectRole'}
          ]
        end
        get '/:id', root: false do
          authenticate!
          ProjectRole.find(params[:id])
        end
      end
    end
  end
end
