module DDS
  module V1
    class FileVersionsAPI < Grape::API
      desc 'List file versions' do
        detail 'If there are previous versions of a file, this action can be used to retrieve information about the older versions.'
        named 'list file versions'
        failure [
          {code: 200, message: 'Valid API Token in \'Authorization\' Header'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'File does not exist'}
        ]
      end
      params do
      end
      get '/files/:id/versions', adapter: :json, root: 'results' do
        authenticate!
        file = DataFile.find(params[:id])
        authorize FileVersion.new(data_file: file), :index?
        policy_scope(file.file_versions)
      end

      desc 'View file version' do
        detail 'view file version'
        named 'view file version'
        failure [
          {code: 200, message: 'Valid API Token in \'Authorization\' Header'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'File does not exist'}
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
          {code: 200, message: 'Valid API Token in \'Authorization\' Header'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'File does not exist'}
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
        file_version.save
        file_version
      end

      desc 'Delete a file version metadata object' do
        detail 'Deletes the file version from view'
        named 'delete file version metadata'
        failure [
          {code: 200, message: 'This will never happen'},
          {code: 204, message: 'Successfully Deleted'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'File version does not exist'}
        ]
      end
      delete '/file_versions/:id/', root: false do
        authenticate!
        file_version = hide_logically_deleted(FileVersion.find(params[:id]))
        authorize file_version, :destroy?
        if file_version.update(is_deleted: true)
          body false
        else
          validation_error!(file_version)
        end
      end

      desc 'Download a file_version' do
        detail 'Generates and returns a storage provider specific pre-signed URL that client can use to download the file version.'
        named 'download file_version'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'File version does not exist, or Upload is not consistent'}
        ]
      end
      get '/file_versions/:id/url', root: false, serializer: FileVersionUrlSerializer do
        authenticate!
        file_version = hide_logically_deleted(FileVersion.find(params[:id]))
        authorize file_version, :download?
        check_consistency! file_version.upload
        check_integrity! file_version.upload
        file_version
      end

      desc 'Promote file version' do
        detail 'promote file version'
        named 'promote file version'
        failure [
          {code: 201, message: 'Valid API Token in \'Authorization\' Header'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'File version does not exist'}
        ]
      end
      post '/file_versions/:id/current', root: false do
        authenticate!
        file_version_params = declared(params, include_missing: false)
        file_version = hide_logically_deleted(FileVersion.find(params[:id]))
        authorize file_version, :create?
        dup_file_version = file_version.dup
        if dup_file_version.save
          dup_file_version
        else
          validation_error!(dup_file_version)
        end
      end
    end
  end
end
