module DDS
  module V1
    class AuthProvidersAPI < Grape::API
      helpers PaginationParams

      helpers do
        def affiliate_not_found_error!
          error_json = {
            "error" => "404",
            "code" => "not_provided",
            "reason" => "Affiliate Not Found",
            "suggestion" => "you may have mistyped the uid"
          }
          error!(error_json, 404)
        end

        def affiliate_exists_error!
          error_json = {
            "error" => "409",
            "code" => "not_provided",
            "reason" => "Affiliate already registered",
            "suggestion" => "nothing else needs to be done"
          }
          error!(error_json, 409)
        end

        def unsupported_affiliate_search_error!
          error_payload = {
            error: '400',
            code: "not_provided",
            reason: 'authentication provider does not support affilate searches',
            suggestion: 'perhaps you are using the wrong authentication provider'
          }
          error!(error_payload, 400)
        end
      end

      desc 'List Authentication Providers' do
        detail 'Lists Authentication Providers'
        named 'list Authentication Providers'
        failure [
          {code: 200, message: 'Success'}
        ]
      end
      params do
        use :pagination
      end
      get '/auth_providers', adapter: :json, root: 'results', each_serializer: AuthenticationServiceSerializer do
        paginate(AuthenticationService)
      end

      desc 'Show Authentication Provider Details' do
        detail 'Show Authentication Provider Details'
        named 'show authentication provider details'
        failure [
          {code: 200, message: 'Success'},
          {code: 404, message: 'Authentication Provider Does not Exist'}
        ]
      end
      get '/auth_providers/:id', root: false, serializer: AuthenticationServiceSerializer do
        AuthenticationService.find(params[:id])
      end

      desc 'List Auth Provider Affiliates' do
        detail 'List Auth Provider Affiliates'
        named 'list authentication provider affiliates'
        failure [
          {code: 200, message: 'Success'},
          {code: 404, message: 'AuthenticationService does not exist'},
          {code: 400, message: 'AuthenticationService does not support affiliate search'},
          {code: 503, message: 'Identity Provider Communication Failure'}
        ]
      end
      params do
        requires :id, type: String, desc: 'AuthenticationProvider UUID'
        optional :full_name_contains, type: String, desc: 'string contained in name(must be at least 3 characters)'
        optional :username, type: String, desc: 'filter by username (exact matches only)'
        optional :email, type: String, desc: 'filter by email (exact matches only)'
      end
      params do
        use :pagination
      end
      get '/auth_providers/:id/affiliates', adapter: :json, root: 'results', each_serializer: AffiliateSerializer do
        affiliate_params = declared(params, {include_missing: false}, [:full_name_contains, :username, :email])
        auth_service = AuthenticationService.find(params[:id])
        unsupported_affiliate_search_error! unless auth_service.identity_provider
        if ENV['FF_LDAP_PAGINATION']
          p = paginate(Kaminari.paginate_array(Array.new(500)))
          auth_service.identity_provider.affiliates_offset = p.offset_value
          auth_service.identity_provider.affiliates_limit = p.limit_value
        end
        affiliates = auth_service.identity_provider.affiliates(**affiliate_params.symbolize_keys)
        affiliates = Kaminari.paginate_array(affiliates)
        paginate(affiliates)
      end

      desc 'View Auth Provider Affiliate' do
        detail 'View Auth Provider Affiliate'
        named 'view_auth_provider_affiliate'
        failure [
          {code: 200, message: 'Success'},
          {code: 404, message: 'AuthenticationService does not exist or Affiliate does not exist in AuthenticationService'},
          {code: 400, message: 'AuthenticationService does not support affiliate search'},
          {code: 401, message: 'Unauthorized'},
          {code: 503, message: 'Identity Provider Communication Failure'}
        ]
      end
      params do
        requires :id, type: String, desc: 'AuthenticationProvider UUID'
        requires :uid, type: String, desc: 'uid of the Affiliate from the AuthenticationProvider'
      end
      get '/auth_providers/:id/affiliates/:uid', root: false, serializer: AffiliateSerializer do
        authenticate!
        affiliate_params = declared(params, {include_missing: false}, [:uid])
        auth_service = AuthenticationService.find(params[:id])
        if auth_service.identity_provider.nil?
          unsupported_affiliate_search_error!
        else
          user = auth_service.identity_provider.affiliate(affiliate_params[:uid])
          if user
            user
          else
            affiliate_not_found_error!
          end
        end
      end

      desc 'Create User Account for Affiliate' do
        detail 'Create User Account for Affiliate'
        named 'create_user_account_for_affiliate'
        failure [
          {code: 201, message: 'Success'},
          {code: 404, message: 'AuthenticationService does not exist or Affiliate does not exist in AuthenticationService'},
          {code: 400, message: 'AuthenticationService does not support affiliate search'},
          {code: 401, message: 'Unauthorized'},
          {code: 503, message: 'Identity Provider Communication Failure'}
        ]
      end
      params do
        requires :id, type: String, desc: 'AuthenticationProvider UUID'
        requires :uid, type: String, desc: 'uid of the Affiliate from the AuthenticationProvider'
      end
      post '/auth_providers/:id/affiliates/:uid/dds_user', root: false do
        authenticate!
        affiliate_params = declared(params, {include_missing: false}, [:uid])
        auth_service = AuthenticationService.find(params[:id])
        if auth_service.identity_provider.nil?
          unsupported_affiliate_search_error!
        else
          if UserAuthenticationService.where(
            uid: affiliate_params[:uid],
            authentication_service_id: auth_service.id
          ).exists?
            affiliate_exists_error!
          else
            user = auth_service.identity_provider.affiliate(affiliate_params[:uid])
            if user
              user.id = SecureRandom.uuid
              authorize user, :create?
              user.user_authentication_services.build(uid: user.username, authentication_service: auth_service)
              if user.save
                user
              else
                validation_error!(user)
              end
            else
              affiliate_not_found_error!
            end
          end
        end
      end
    end
  end
end
