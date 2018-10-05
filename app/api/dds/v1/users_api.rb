module DDS
  module V1
    class UsersAPI < Grape::API
      helpers PaginationParams

      desc 'api_token' do
        detail 'This allows a client to present an access token from a registered authentication service and get an api token'
        named 'api_token'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Missing, or invalid Access Token'}
        ]
      end
      params do
        requires :access_token
        optional :authentication_service_id, type: String, desc: 'authentication service uuid'
      end
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        if e.errors.keys.flatten.include?('access_token')
          error_json = {
            "error" => 400,
            "code" => "not_provided",
            "reason" => "no access_token",
            "suggestion" => "you might need to login through an authentication service"#,
          }
          error!(error_json, 400)
        else
          error!(e.message, 400)
        end
      end
      get '/user/api_token', serializer: ApiTokenSerializer do
        token_info_params = declared(params)

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
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'}
        ]
      end
      params do
        optional :last_name_begins_with, type: String, desc: 'list users whose last name begins with this string'
        optional :first_name_begins_with, type: String, desc: 'list users whose first name begins with this string'
        optional :full_name_contains, type: String, desc: 'list users whose full name contains this string'
        optional :username, type: String, desc: 'list users whose username matches this string'
        use :pagination
      end
      get '/users', adapter: :json, root: 'results' do
        authenticate!
        query_params = declared(params, include_missing: false)
        users = UserFilter.new(query_params).query(User.all).order(last_name: :asc)
        users = users.where(username: query_params[:username]) if query_params[:username]
        paginate(users)
      end

      desc 'View user details' do
        detail 'Returns the user details for a given uuid of a user.'
        named 'view user'
        failure [
          {code: 200, message: 'Valid API Token in \'Authorization\' Header'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'User does not exist'}
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
