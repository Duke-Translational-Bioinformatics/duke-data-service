module DDS
  module V1
    class UploadsAPI < Grape::API
      desc 'Initiate a chunked file upload for a project' do
        detail 'This is the first step in uploading a large file. An upload objects is created along with a composite status object used to track the progress of the chunked upload.'
        named 'create upload'
        failure [401]
      end
      params do
        requires :name
        requires :content_type
        requires :size
        requires :hash, type: Hash do
          requires :value
          requires :algorithm
        end
      end
      post '/projects/:project_id/uploads', root: false do
        authenticate!
        upload_params = declared(params, include_missing: false)
        #TODO: Check that project actually exists and throw an error
        # if it doesn't
        #project = Project.find(params[:project_id])
        storage_provider = StorageProvider.first
        upload = Upload.new({
          project_id: params[:project_id],
          name: upload_params[:name],
          size: upload_params[:size],
          fingerprint_value: upload_params[:hash][:value],
          fingerprint_algorithm: upload_params[:hash][:algorithm],
          storage_provider_id: storage_provider.id
        })
        if upload.save
          upload
        else
          validation_error!(upload)
        end
      end

      desc 'List file uploads for a project' do
        detail 'List file uploads for a project'
        named 'list uploads'
        failure [401]
      end
      get '/projects/:project_id/uploads', root: false do
        authenticate!
        Upload.all
      end

      desc 'View upload details/status' do
        detail 'View upload details/status'
        named 'show upload'
        failure [401]
      end
      get '/uploads/:id/', root: false do
        authenticate!
        Upload.find(params[:id])
      end

      desc 'Get pre-signed URL to upload the next chunk' do
        detail 'Get pre-signed URL to upload the next chunk'
        named 'create chunk'
        failure [401]
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
        if chunk.save
          chunk
        else
          validation_error!(chunk)
        end
      end

      desc 'Complete the chunked file upload' do
        detail 'Complete the chunked file upload'
        named 'complete upload'
        failure [401]
      end
      put '/uploads/:id/complete', root: false do
        authenticate!
        upload = Upload.find(params[:id])
        upload.touch
        upload
      end
    end
  end
end
