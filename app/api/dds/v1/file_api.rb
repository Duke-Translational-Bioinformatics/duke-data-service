module DDS
  module V1
    class FileAPI < Grape::API
      desc 'Create a file' do
        detail 'Creates a project file for the given payload.'
        named 'create project file'
        failure [
          [200, "this will never happen"],
          [201, "Successfully Created"],
          [400, 'Upload has an IntegrityException'],
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
        file = project.data_files.build({
          upload_id: upload.id,
          name: upload.name,
          audit_comment: {action: request.env["REQUEST_URI"]}
        })
        if file_params[:parent] && file_params[:parent][:id]
          project.folders.find(file_params[:parent][:id])
          file.parent_id = file_params[:parent][:id]
        end
        authorize file, :create?
        Audited.audit_class.as_user(current_user) do
          if file.save
            file.audits.last.update(remote_address: request.ip)
            file
          else
            validation_error!(file)
          end
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
            file = DataFile.find(params[:id])
            authorize file, :show?
            file
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
            authorize file, :destroy?
            Audited.audit_class.as_user(current_user) do
              file.update(is_deleted: true, audit_comment: {action: request.env["REQUEST_URI"]})
              file.audits.last.update(remote_address: request.ip)
            end
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
            authorize file, :download?
            new_url = "#{file.upload.storage_provider.url_root}#{file.upload.temporary_url}"
            redirect new_url, permanent: true
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
            authorize file, :move?
            Audited.audit_class.as_user(current_user) do
              file.update(parent_id: new_parent.id, audit_comment: {action: request.env["REQUEST_URI"]})
              file.audits.last.update(remote_address: request.ip)
            end
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
            authorize file, :rename?
            Audited.audit_class.as_user(current_user) do
              file.update(name: file_params[:name], audit_comment: {action: request.env["REQUEST_URI"]})
              file.audits.last.update(remote_address: request.ip)
            end
            file
          end
        end
      end
    end
  end
end
