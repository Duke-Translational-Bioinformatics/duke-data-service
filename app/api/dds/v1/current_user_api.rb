module DDS
  module V1
    class CurrentUserAPI < Grape::API
      desc 'current_user' do
        detail 'allows a user to get their User object with a valid api_token'
        named 'current_user'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in 'Authorization' Header'}
        ]
      end
      get '/current_user', root: false do
        authenticate!
        current_user
      end

      desc 'current_user usage' do
        detail 'get data about user projects, files, and storage usage'
        named 'current_user usage'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in 'Authorization' Header'}
        ]
      end
      get '/current_user/usage', serializer: UserUsageSerializer do
        authenticate!
        current_user
      end

      desc 'manage current_user api_key' do
        detail 'create or recreate the current_user api_key'
        named 'manage current_user api_key'
        failure [
          {code: 201, message: 'Success'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in 'Authorization' Header'},
          {code: 403, message: 'Forbidden (software_agent restricted)'}
        ]
      end
      put '/current_user/api_key', serializer: ApiKeySerializer do
        authenticate!
        ApiKey.transaction do
          if current_user.api_key
            authorize current_user.api_key, :update?
            original_api_key_id = current_user.api_key.id
            current_user.api_key.destroy!
          end
          current_user.build_api_key(key: SecureRandom.hex)
          authorize current_user.api_key, :create?
          current_user.save
        end
        current_user.api_key
      end

      desc 'View Current User API key' do
        detail 'View current_user api_key.'
        named 'view current_user api_key'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden (software_agent restricted)'},
          {code: 404, message: 'Current User or ApiKey Does not Exist'}
        ]
      end
      get '/current_user/api_key', serializer: ApiKeySerializer do
        authenticate!
        if current_user.api_key
          authorize current_user.api_key, :show?
          current_user.api_key
        else
          error_json = {
            "error" => "404",
            "code" => "not_provided",
            "reason" => "ApiKey Not Found",
            "suggestion" => "you must create an ApiKey"
          }
          error!(error_json, 404)
        end
      end

      desc 'Delete a Current User API key' do
        detail 'Delete a Current User API key'
        named 'delete current_user api_key'
        failure [
          {code: 204, message: 'Successfully Deleted'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden (software_agent restricted)'},
          {code: 404, message: 'Current User Does not Exist'}
        ]
      end
      delete '/current_user/api_key', root: false do
        authenticate!
        authorize current_user.api_key, :destroy?
        current_user.api_key.destroy!
        body false
      end
    end
  end
end
