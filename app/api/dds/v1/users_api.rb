module DDS
  module V1
    class UsersAPI < Grape::API
      helpers PaginationParams

      desc 'api_token' do
        detail 'This allows a client to present an access token from a registred authentication service and get an api token'
        named 'api_token'
        failure [
          [200,'Success'],
          [401, 'Missing, or invalid Access Token']
        ]
      end
      params do
        requires :access_token
        optional :authentication_service_id, type: String, desc: 'authentication service uuid'
      end
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error_json = {
          "error" => 400,
          "reason" => "no access_token",
          "suggestion" => "you might need to login through an authentication service"#,
        }
        error!(error_json, 400)
      end
      rescue_from InvalidAccessTokenException do
        error!({
          error: 401,
          reason: 'invalid access_token',
          suggestion: 'token not properly signed'
        },401)
      end
    rescue_from InvalidAuthenticationServiceIDException do
      error!({
        error: 401,
        reason: 'invalid access_token',
        suggestion: 'authentication service not registered'
      },401)
    end
      get '/user/api_token', serializer: ApiTokenSerializer do
        token_info_params = declared(params)
        raise InvalidAccessTokenException.new unless token_info_params[:access_token]

        auth_service = get_auth_service(
          token_info_params[:authentication_service_id])
        authorized_user = auth_service.get_user_for_access_token(token_info_params[:access_token])
        authorized_user.last_login_at = DateTime.now
        populate_audit_store_with_user(authorized_user)
        if authorized_user.save
          api_token = ApiToken.new(user: authorized_user, user_authentication_service:authorized_user.current_user_authenticaiton_service)
          api_token
        else
          validation_error!(authorized_user)
        end
      end

      desc 'users' do
        detail 'This allows a client to get a list of users, with an optional filter'
        named 'users'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      params do
        optional :last_name_begins_with, type: String, desc: 'list users whose last name begins with this string'
        optional :first_name_begins_with, type: String, desc: 'list users whose first name begins with this string'
        optional :full_name_contains, type: String, desc: 'list users whose full name contains this string'
        use :pagination
      end
      get '/users', root: 'results' do
        authenticate!
        query_params = declared(params, include_missing: false)
        users = UserFilter.new(query_params).query(User.all).order(last_name: :asc)
        paginate(users)
      end

      desc 'View user details' do
        detail 'Returns the user details for a given uuid of a user.'
        named 'view user'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'User does not exist']
        ]
      end
      params do
        requires :id, type: String, desc: 'User UUID'
      end
      get '/users/:id', root: false do
        authenticate!
        user = User.find(params[:id])
        user
      end

    end
  end
end
