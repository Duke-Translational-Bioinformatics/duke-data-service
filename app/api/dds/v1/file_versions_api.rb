module DDS
  module V1
    class FileVersionsAPI < Grape::API
      desc 'List file versions' do
        detail 'If there are previous versions of a file, this action can be used to retrieve information about the older versions.'
        named 'list file versions'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      params do
      end
      get '/files/:id/versions', root: 'results' do
        authenticate!
        file = DataFile.find(params[:id])
        authorize FileVersion.new(data_file: file), :index?
        policy_scope(file.file_versions)
      end

      desc 'View file version' do
        detail 'view file version'
        named 'view file version'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      params do
      end
      get '/file_versions/:id', root: false do
        authenticate!
        file_version = FileVersion.find(params[:id])
        authorize file_version, :show?
        file_version
      end

      desc 'Update file version' do
        detail 'update file version'
        named 'update file version'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File does not exist']
        ]
      end
      params do
        optional :label
      end
      put '/file_versions/:id', root: false do
        authenticate!
        file_version_params = declared(params, include_missing: false)
        file_version = hide_logically_deleted(FileVersion.find(params[:id]))
        authorize file_version, :update?
        file_version.label = file_version_params[:label] if file_version_params[:label]
        Audited.audit_class.as_user(current_user) do
          file_version.save
          annotate_audits [file_version.audits.last]
          file_version
        end
      end

      desc 'Delete a file version metadata object' do
        detail 'Deletes the file version from view'
        named 'delete file version metadata'
        failure [
          [200, "This will never happen"],
          [204, 'Successfully Deleted'],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File version does not exist']
        ]
      end
      delete '/file_versions/:id/', root: false do
        authenticate!
        file_version = hide_logically_deleted(FileVersion.find(params[:id]))
        authorize file_version, :destroy?
        Audited.audit_class.as_user(current_user) do
          if file_version.update(is_deleted: true)
            annotate_audits [file_version.audits.last]
          else
            validation_error!(file_version)
          end
        end
        body false
      end

      desc 'Download a file_version' do
        detail 'Generates and returns a storage provider specific pre-signed URL that client can use to download the file version.'
        named 'download file_version'
        failure [
          [200, "This will never happen"],
          [301, 'Redirect to file version'],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File version does not exist']
        ]
      end
      get '/file_versions/:id/url', root: false, serializer: FileVersionUrlSerializer do
        authenticate!
        file_version = hide_logically_deleted(FileVersion.find(params[:id]))
        authorize file_version, :download?
        file_version
      end

      desc 'Promote file version' do
        detail 'promote file version'
        named 'promote file version'
        failure [
          [201, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'File version does not exist']
        ]
      end
      post '/file_versions/:id/current', root: false do
        authenticate!
        file_version_params = declared(params, include_missing: false)
        file_version = hide_logically_deleted(FileVersion.find(params[:id]))
        authorize file_version, :create?
        dup_file_version = file_version.dup
        Audited.audit_class.as_user(current_user) do
          if dup_file_version.save
            annotate_audits [dup_file_version.audits.last]
            dup_file_version
          else
            validation_error!(dup_file_version)
          end
        end
      end
    end
  end
end
