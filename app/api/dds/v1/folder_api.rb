module DDS
  module V1
    class FolderAPI < Grape::API
      desc 'Create a project folder' do
        detail 'Creates a project folder for the given payload.'
        named 'create project folder'
        failure [401]
      end
      params do
        requires :parent
        requires :name
      end
      post '/projects/:id/folders', root: false do
        authenticate!
        folder_params = declared(params, include_missing: false)
        project = Project.find(params[:id])
        folder = project.folders.build({
          project: project,
          parent_id: folder_params[:parent][:id],
          name: folder_params[:name]
        })
        if folder.save
          folder
        else
          validation_error!(folder)
        end
      end

      desc 'List folders' do
        detail 'Lists folders for a given project.'
        named 'list folders'
        failure [401]
      end
      get '/projects/:id/folders', root: false do
        authenticate!
        results = []
        Folder.where(project_id: params[:id]).find_each do |folder|
          results.push(folder)
        end
        results
      end

      desc 'View folder details' do
        detail 'Returns the folder details for a given uuid of a folder.'
        named 'view folder'
        failure [401]
      end
      get '/folders/:id', root: false do
        authenticate!
        Folder.find(params[:id])
      end

      desc 'Delete a folder' do
        detail 'Remove the folder for a given uuid.'
        named 'delete folder'
        failure [401]
      end
      delete '/folders/:id', root: false do
        authenticate!
        folder = Folder.find(params[:id])
        folder.update_attribute(:is_deleted, true)
        body false
      end

      desc 'Move a folder' do
        detail 'Move a folder with a given uuid to a new parent.'
        named 'move folder'
        failure [401]
      end
      params do
        requires :parent
      end
      put '/folders/:id/move', root: false do
        authenticate!
        folder_params = declared(params, include_missing: false)
        new_parent = folder_params[:parent][:id]
        folder = Folder.find(params[:id])
        if folder.update(parent_id: new_parent)
          folder
        else
          validation_error!(folder)
        end
      end

      desc 'Rename a folder' do
        detail 'Give a folder with a given uuid a new name.'
        named 'rename folder'
        failure [401]
      end
      params do
        requires :name
      end
      put '/folders/:id/rename', root: false do
        authenticate!
        folder_params = declared(params, include_missing: false)
        new_name = folder_params[:name]
        folder = Folder.find(params[:id])
        if folder.update(name: new_name)
          folder
        else
          validation_error!(folder)
        end
      end
    end
  end
end
