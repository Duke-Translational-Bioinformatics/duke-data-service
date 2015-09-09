module DDS
  module V1
    class ProjectRolesAPI < Grape::API
      namespace :project_roles do
        desc 'List project roles' do
          detail 'Lists project roles.'
          named 'list project roles'
          failure [
            [200, 'Success'],
            [401, 'Unauthorized']
          ]
        end
        get '/', root: false do
          authenticate!
          ProjectRole.all
        end

        desc 'View project role details' do
          detail 'View project role details.'
          named 'view project role'
          failure [
            [200, 'Success'],
            [401, 'Unauthorized'],
            [404, 'Unkown ProjectRole']
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
