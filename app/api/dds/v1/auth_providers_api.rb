module DDS
  module V1
    class AuthProvidersAPI < Grape::API
      helpers PaginationParams

      desc 'List Authentication Providers' do
        detail 'Lists Authentication Providers'
        named 'list Authentication Providers'
        failure [
          [200, 'Success']
        ]
      end
      params do
        use :pagination
      end
      get '/auth_providers', root: 'results', each_serializer: AuthenticationServiceSerializer do
        paginate(AuthenticationService)
      end

      desc 'Show Authentication Provider Details' do
        detail 'Show Authentication Provider Details'
        named 'show authentication provider details'
        failure [
          [200, 'Success'],
          [404, 'Authentication Provider Does not Exist']
        ]
      end
      get '/auth_providers/:id', root: false, serializer: AuthenticationServiceSerializer do
        AuthenticationService.find(params[:id])
      end
    end
  end
end
