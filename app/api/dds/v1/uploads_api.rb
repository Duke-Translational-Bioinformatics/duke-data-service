module DDS
  module V1
    class UploadsAPI < Grape::API
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
        requires :name, type: String, desc: "The name of the client file to upload."
        requires :content_type, type: String, desc: "Valid Media Type"
        requires :size, type: Integer, desc: "The size in bytes"
        requires :hash, type: Hash do
          requires :value, type: String, desc: "The files hash computed by the client."
          requires :algorithm, type: String, desc: "The hash algorithm used (i.e. md5, sha256, sha1, etc.)"
        end
      end
      post '/projects/:project_id/uploads', root: false do
        authenticate!
        upload_params = declared(params, include_missing: false)
        project = Project.find(params[:project_id])
        storage_provider = StorageProvider.first
        upload = project.uploads.build({
          name: upload_params[:name],
          size: upload_params[:size],
          fingerprint_value: upload_params[:hash][:value],
          fingerprint_algorithm: upload_params[:hash][:algorithm],
          storage_provider_id: storage_provider.id
        })
        authorize upload, :create?
        if upload.save
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
      get '/projects/:project_id/uploads', root: 'results' do
        authenticate!
        project = Project.find(params[:project_id])
        authorize project, :show?
        project.uploads.all
      end

      desc 'View upload details/status' do
        detail 'View upload details/status'
        named 'show upload'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [404, 'Upload Does not Exist']
        ]
      end
      get '/uploads/:id/', root: false do
        authenticate!
        upload = Upload.find(params[:id])
        authorize upload, :show?
        upload
      end

      desc 'Get pre-signed URL to upload the next chunk' do
        detail 'Get pre-signed URL to upload the next chunk'
        named 'create chunk'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [404, 'Upload Does not Exist']
        ]
      end
      params do
        requires :number
        requires :size
        requires :hash, type: Hash do
          requires :value
          requires :algorithm
        end
      end
      put '/uploads/:id/chunks', root: false do
        authenticate!
        chunk_params = declared(params, include_missing: false)
        upload = Upload.find(params[:id])
        chunk = Chunk.new({
          upload_id: upload.id,
          number: chunk_params[:number],
          size: chunk_params[:size],
          fingerprint_value: chunk_params[:hash][:value],
          fingerprint_algorithm: chunk_params[:hash][:algorithm]
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
          [404, 'Upload Does not Exist']
        ]
      end
      put '/uploads/:id/complete', root: false do
        authenticate!
        upload = Upload.find(params[:id])
        authorize upload, :complete?
        upload.touch
        upload
      end
    end
  end
end
