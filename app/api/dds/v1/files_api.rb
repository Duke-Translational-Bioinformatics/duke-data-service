module DDS
  module V1
    class FilesAPI < Grape::API
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
        requires :parent, desc: "Parent Folder ID", type: Hash do
          requires :kind, type: String, desc: "Parent kind"
          requires :id, type: String, desc: "Parent UUID"
        end
        requires :upload, desc: "Upload", type: Hash do
          requires :id, type: String, desc: "Upload UUID"
        end
        optional :label
      end
      post '/files', root: false do
        authenticate!
        file_params = declared(params, include_missing: false)
        if file_params[:parent][:kind] == Project.new.kind
          project = hide_logically_deleted(Project.find(file_params[:parent][:id]))
        else
          parent = hide_logically_deleted(Folder.find(file_params[:parent][:id]))
          project = hide_logically_deleted(parent.project)
        end
        upload = project.uploads.find(file_params[:upload][:id])
        file = project.data_files.build({
          parent: parent,
          upload: upload,
          name: upload.name,
          label: file_params[:label],
          creator_id: current_user.id
        })
        authorize file, :create?
        Audited.audit_class.as_user(current_user) do
          if file.save
            annotate_audits [file.audits.last]
            file
          else
            file
            validation_error!(file)
          end
        end
      end

      desc 'View file metadata object details' do
        detail 'Access metadata details about a file.'
        named 'view file metadata'
        failure [
          [200, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      get '/files/:id/', root: false do
        authenticate!
        file = DataFile.find(params[:id])
        authorize file, :show?
        file
      end

      desc 'Update file properties' do
        detail 'Updates one or more file resource properties; if this action modifies the upload property, the previous file resource is transitioned to version history (see File Versions)'
        named 'update file'
        failure [
          [200, 'Success'],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      params do
        optional :upload, desc: "Upload", type: Hash do
          requires :id, type: String, desc: "Upload UUID"
        end
        optional :label
      end
      put '/files/:id/', root: false do
        authenticate!
        file = hide_logically_deleted(DataFile.find(params[:id]))
        file_params = declared(params, include_missing: false)
        file.upload = Upload.find(params[:upload][:id]) if params[:upload]
        file.label = params[:label] if params[:label]
        authorize file, :update?
        Audited.audit_class.as_user(current_user) do
          if file.save
            annotate_audits [file.audits.last]
            file
          else
            validation_error! file
          end
        end
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
      delete '/files/:id/', root: false do
        authenticate!
        file = hide_logically_deleted(DataFile.find(params[:id]))
        authorize file, :destroy?
        Audited.audit_class.as_user(current_user) do
          file.update_attribute(:is_deleted, true)
          annotate_audits [file.audits.last]
        end
        body false
      end

      desc 'Download a file' do
        detail 'Generates and returns a storage provider specific pre-signed URL that client can use to download file.'
        named 'download file'
        failure [
          [200, "This will never happen"],
          [301, 'Redirect to file'],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      get '/files/:id/url', root: false, serializer: DataFileUrlSerializer do
        authenticate!
        file = hide_logically_deleted(DataFile.find(params[:id]))
        authorize file, :download?
        file
      end

      desc 'Move file' do
        detail 'Move a file metadata object to a new parent'
        named 'move file'
        failure [
          [200, 'Success'],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist, Parent does not exist in Project']
        ]
      end
      params do
        requires :parent, type: Hash do
          requires :kind, desc: 'Parent kind', type: String
          requires :id, desc: 'Parent ID', type: String
        end
      end
      put '/files/:id/move', root: false do
        authenticate!
        file = hide_logically_deleted(DataFile.find(params[:id]))
        file_params = declared(params, include_missing: false)
        update_params = {parent: nil}
        if file_params[:parent][:kind] == Project.new.kind
          update_params[:project] = hide_logically_deleted Project.find(file_params[:parent][:id])
        else
          update_params[:parent] = hide_logically_deleted Folder.find(file_params[:parent][:id])
        end
        authorize file, :move?
        Audited.audit_class.as_user(current_user) do
          if file.update(update_params)
            annotate_audits [file.audits.last]
            file
          else
            validation_error! file
          end
        end
      end

      desc 'Rename file' do
        detail 'Rename a file metadata object'
        named 'rename file'
        failure [
          [200, 'Success'],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      params do
        requires :name, type: String, desc: 'New name for File'
      end
      put '/files/:id/rename', root: false do
        authenticate!
        file = hide_logically_deleted(DataFile.find(params[:id]))
        file_params = declared(params, include_missing: false)
        authorize file, :rename?
        Audited.audit_class.as_user(current_user) do
          if file.update(name: file_params[:name])
            annotate_audits [file.audits.last]
            file
          else
            validation_error! file
          end
        end
      end
    end
  end
end
