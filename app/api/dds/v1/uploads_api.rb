module DDS
  module V1
    class UploadsAPI < Grape::API
      helpers PaginationParams

      namespace :projects do
        route_param :project_id do
          desc 'Initiate a chunked file upload for a project' do
            detail 'This is the first step in uploading a large file. An upload objects is created along with a composite status object used to track the progress of the chunked upload.'
            named 'create upload'
            failure [
              [200, 'This will never actually happen'],
              [201, 'Created Successfully'],
              [401, 'Unauthorized'],
              [404, 'Project Does not Exist']
            ]
          end
          params do
            requires :project_id, type: String, desc: "The ID of the Project"
            requires :name, type: String, desc: "The name of the client file to upload."
            requires :content_type, type: String, desc: "Valid Media Type"
            requires :size, type: Integer, desc: "The size in bytes"
          end
          post '/uploads', root: false do
            authenticate!
            upload_params = declared(params, include_missing: false)
            project = hide_logically_deleted Project.find(params[:project_id])
            storage_provider = StorageProvider.first
            upload = project.uploads.build({
              name: upload_params[:name],
              size: upload_params[:size],
              etag: SecureRandom.hex,
              content_type: upload_params[:content_type],
              storage_provider_id: storage_provider.id,
              creator: current_user
            })
            authorize upload, :create?
            if upload.save
              upload.initialize_storage_provider
              upload
            else
              validation_error!(upload)
            end
          end

          desc 'List file uploads for a project' do
            detail 'List file uploads for a project'
            named 'list uploads'
            failure [
              [200, 'Success'],
              [401, 'Unauthorized'],
              [404, 'Project Does not Exist']
            ]
          end
          params do
            requires :project_id, type: String, desc: "The ID of the Project"
            use :pagination
          end
          get '/uploads', root: 'results' do
            authenticate!
            project = hide_logically_deleted Project.find(params[:project_id])
            authorize Upload.new(project: project), :index?
            uploads = policy_scope(project.uploads)
            paginate(uploads.all)
          end
        end
      end

      namespace :uploads do
        route_param :id do
          desc 'View upload details/status' do
            detail 'View upload details/status'
            named 'show upload'
            failure [
              [200, 'Success'],
              [401, 'Unauthorized'],
              [404, 'Upload Does not Exist']
            ]
          end
          params do
            requires :id, type: String, desc: "Globally unique id of the upload object."
          end
          get '/', root: false do
            authenticate!
            upload = Upload.find(params[:id])
            authorize upload, :show?
            upload
          end

          desc 'Get pre-signed URL to upload the next chunk' do
            detail 'Get pre-signed URL to upload the next chunk. This will also ensure that the project container exists in the storage_provider.'
            named 'create chunk'
            failure [
              [200, 'Success'],
              [401, 'Unauthorized'],
              [404, 'Upload Does not Exist'],
              [500, 'Unexpected StorageProviderException experienced']
            ]
          end
          params do
            requires :id, type: String, desc: 'The Upload Id'
            requires :number, type: Integer, desc: 'The chunk number.'
            requires :size, type: Integer, desc: 'The size of the chunk in bytes that the client will upload using the pre-signed URL.'
            requires :hash, type: Hash do
              requires :value, type: String, desc: 'The chunk hash computed by the client.'
              requires :algorithm, type: String, desc: 'The hash algorithm used (i.e. md5, sha256, sha1, etc.) - this must be the default algorithm supported by storage provider.'
            end
          end
          put '/chunks', root: false do
            authenticate!
            chunk_params = declared(params, include_missing: false)
            upload = Upload.find(params[:id])
            chunk = Chunk.new({
              upload_id: upload.id,
              number: chunk_params[:number],
              size: chunk_params[:size],
              fingerprint_value: chunk_params[:hash][:value],
              fingerprint_algorithm: chunk_params[:hash][:algorithm],
            })
            authorize chunk, :create?
            if chunk.save
              chunk
            else
              validation_error!(chunk)
            end
          end

          desc 'Complete the chunked file upload' do
            detail 'Complete the chunked file upload'
            named 'complete upload'
            failure [
              [200, 'Success'],
              [401, 'Unauthorized'],
              [404, 'Upload Does not Exist'],
              [400, 'IntegrityException: reported file size or chunk hashes do not match that computed by StorageProvider'],
              [500, 'Unexpected StorageProviderException experienced']
            ]
          end
          rescue_from IntegrityException do |e|
            error_json = {
              "error" => "400",
              "reason" => "IntegrityException",
              "suggestion" => e.message
            }
            error!(error_json, 400)
          end
          params do
            requires :hash, type: Hash do
              requires :value, type: String, desc: "The entire file hash (computed by client)."
              requires :algorithm, type: String, desc: "The algorithm used by client to compute entire file hash (i.e. md5, sha256, sha1, etc.)."
            end
          end
          put '/complete', root: false do
            authenticate!
            upload = Upload.find(params[:id])
            authorize upload, :complete?
            fingerprint_params = declared(params, include_missing: false)
            upload.fingerprints_attributes = [fingerprint_params[:hash]]
            upload.etag = SecureRandom.hex
            if upload.complete
              upload
            else
              validation_error!(upload)
            end
          end

          desc 'Report upload hash' do
            detail 'Report hash (fingerprint) for the uploaded (or to be uploaded) file.'
            named 'report upload hash'
            failure [
              [200, 'Success'],
              [401, 'Unauthorized'],
              [404, 'Upload Does not Exist'],
              [400, 'Validation Error'],
              [500, 'Unexpected StorageProviderException experienced']
            ]
          end
          params do
            requires :value, type: String, desc: "The entire file hash (computed by client)."
            requires :algorithm, type: String, desc: "The algorithm used by client to compute entire file hash (i.e. md5, sha256, sha1, etc.)."
          end
          put '/hashes', root: false do
            authenticate!
            fingerprint_params = declared(params, include_missing: false)
            upload = Upload.find(params[:id])
            authorize upload, :update?
            fingerprint = upload.fingerprints.build(fingerprint_params)
            if upload.save
              upload
            else
              validation_error!(upload)
            end
          end
        end
      end
    end
  end
end
