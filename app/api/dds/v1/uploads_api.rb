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
      post '/project/:project_id/uploads', root: false do
        authenticate!
        upload_params = declared(params, include_missing: false)
        project = Project.find(params[:project_id])
        upload = Upload.new({
          name: upload_params[:name]
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
      get '/project/:project_id/uploads', root: false do
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
