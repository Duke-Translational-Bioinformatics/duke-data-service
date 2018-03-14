module DDS
  module V1
    class FilesAPI < Grape::API
      helpers PaginationParams

      desc 'List project files' do
        detail 'Returns all files for the project.'
        named 'list project files'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Project does not exist']
        ]
      end
      params do
        use :pagination
      end
      get '/projects/:id/files', adapter: :json, root: 'results', each_serializer: DataFileSummarySerializer do
        authenticate!
        project = hide_logically_deleted Project.find(params[:id])
        authorize DataFile.new(project: project), :download?
        files = project.data_files.unscope(:order).order(updated_at: :desc).where(is_deleted: false)

        files_query = headers&.fetch("Project-Files-Query", nil) || "plain"

        case files_query
        when 'preload_only'
          # includes query, no joins + preloaded associations
          files = files.includes(file_versions: [upload: [:fingerprints, :storage_provider]])
        when 'join_only'
          # includes query with reference, one join + no preloading
          files = files.includes(file_versions: [upload: [:fingerprints, :storage_provider]]).references(:file_versions)
        when 'join_and_preload'
          # join :file_versions, preload other associations
          files = files.includes(:file_versions).references(:file_versions).preload(file_versions: [upload: [:fingerprints, :storage_provider]])
        end

        logger.info "Project-Files-Query = #{files_query}"

        paginate(files)
      end

      desc 'Create a file' do
        detail 'Creates a project file for the given payload.'
        named 'create project file'
        failure [
          [200, "This will never happen"],
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
          label: file_params[:label]
        })
        authorize file, :create?
        if file.save
          file
        else
          validation_error!(file)
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
        initial_file_version = file.current_file_version
        file_params = declared(params, include_missing: false)
        file.upload = Upload.find(file_params[:upload][:id]) if file_params[:upload]
        file.label = file_params[:label] if file_params[:label]
        authorize file, :update?
        if file.save
          file
        else
          validation_error! file
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
        file.update_attribute(:is_deleted, true)
        body false
      end

      desc 'Download a file' do
        detail 'Generates and returns a storage provider specific pre-signed URL that client can use to download file.'
        named 'download file'
        failure [
          [200, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist, or Upload is not consistent']
        ]
      end
      get '/files/:id/url', root: false, serializer: DataFileUrlSerializer do
        authenticate!
        file = hide_logically_deleted(DataFile.find(params[:id]))
        authorize file, :download?
        check_consistency! file.upload
        check_integrity! file.upload
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
        if file.update(update_params)
          file
        else
          validation_error! file
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
        if file.update(name: file_params[:name])
          file
        else
          validation_error! file
        end
      end
    end
  end
end
