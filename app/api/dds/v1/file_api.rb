module DDS
  module V1
    class FileAPI < Grape::API
      desc 'Create a file' do
        detail 'Creates a project file for the given payload.'
        named 'create project file'
        failure [
          [200, "this will never happen"],
          [201, "Successfully Created"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Project Does not Exist, Parent Folder or Upload does not exist in Project']
        ]
      end
      params do
        optional :parent, desc: "Parent Folder ID", type: Hash do
          requires :id, type: String, desc: "Parent Folder UUID"
        end
        requires :upload, desc: "Upload", type: Hash do
          requires :id, type: String, desc: "Upload UUID"
        end
      end
      post '/projects/:id/files', root: false do
        authenticate!
        file_params = declared(params, include_missing: false)
        project = Project.find(params[:id])
        upload = project.uploads.find(file_params[:upload][:id])
        if params[:parent][:id]
          project.folders.find(params[:parent][:id])
        end
        file = project.data_files.build({
          parent_id: file_params[:parent][:id],
          upload_id: upload.id,
          name: upload.name
        })
        if file.save
          file
        else
          validation_error!(file)
        end
      end

      namespace :files do
        route_param :id do

          desc 'View file metadata object details' do
            detail 'Access metadata details about a file.'
            named 'view file metadata'
            failure [
              [200, "Success"],
              [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
              [404, 'File does not exist']
            ]
          end
          get '/', root: false do
            authenticate!
            DataFile.find(params[:id])
          end

          desc 'Delete a file metadata object' do
            detail 'Deletes the file from view'
            named 'delete file metadata'
            failure [
              [200, "This will never happen"],
              [204, 'Successfully Deleted'],
              [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
              [404, 'File does not exist']
            ]
          end
          delete '/', root: false do
            authenticate!
            file = DataFile.find(params[:id])
            file.update_attribute(:is_deleted, true)
            body false
          end

          desc 'Download a file' do
            detail 'Streams the contents of the file itself'
            named 'download file'
            failure [
              [200, "This will never happen"],
              [301, 'Redirect to file'],
              [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
              [404, 'File does not exist']
            ]
          end
          get '/download', root: false do
            authenticate!
            file = DataFile.find(params[:id])
            redirect file.upload.temporary_url, permanent: true
          end

          desc 'Move a file metadata object to a new parent folder' do
            detail 'Move a file metadata object to a new parent folder'
            named 'move file'
            failure [
              [200, 'Success'],
              [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
              [404, 'File does not exist, Parent does not exist in Project']
            ]
          end
          params do
            requires :parent, desc: "Parent Folder ID", type: Hash do
              requires :id, type: String, desc: 'Folder UUID'
            end
          end
          put '/move', root: false do
            authenticate!
            file = DataFile.find(params[:id])
            file_params = declared(params, include_missing: false)
            new_parent = file.project.folders.find(file_params[:parent][:id])
            file.update_attribute(:parent_id, new_parent.id)
            file
          end

          desc 'Rename a file metadata object' do
            detail 'Rename a file metadata object'
            named 'rename file'
            failure [
              [200, 'Success'],
              [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
              [404, 'File does not exist']
            ]
          end
          params do
            requires :name, type: String, desc: 'New Name for File'
          end
          put '/rename', root: false do
            authenticate!
            file = DataFile.find(params[:id])
            file_params = declared(params, include_missing: false)
            file.update_attribute(:name, file_params[:name])
            file
          end
        end
      end
    end
  end
end
