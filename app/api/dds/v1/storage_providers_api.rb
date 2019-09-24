module DDS
  module V1
    class StorageProvidersAPI < Grape::API
      desc 'List storage providers' do
        detail 'Returns a list of all storage providers'
        named 'list storage providers'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'}
        ]
      end
      get '/storage_providers', adapter: :json, root: 'results' do
        authenticate!
        StorageProvider.all
      end

      desc 'View storage provider' do
        detail 'Returns the storage providers for a given user'
        named 'show storage providers'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'StorageProvider Does not Exist'}
        ]
      end
      params do
        requires :id, type: String, desc: 'StorageProvider UUID'
      end
      get '/storage_providers/:id', root: false do
        authenticate!
        storage_provider = StorageProvider.find(params[:id])
        storage_provider
       end
    end
  end
end
