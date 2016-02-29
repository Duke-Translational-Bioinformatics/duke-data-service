module DDS
  module V1
    class CurrentUserAPI < Grape::API
      desc 'current_user' do
        detail 'allows a user to get their User object with a valid api_token'
        named 'current_user'
        failure [
          [200, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"]
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
          [200, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"]
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
          [201, "Success"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"]
        ]
      end
      put '/current_user/api_key', serializer: ApiKeySerializer do
        authenticate!
        Audited.audit_class.as_user(current_user) do
          ApiKey.transaction do
            audits_to_annotate = []
            if current_user.api_key
              original_api_key_id = current_user.api_key.id
              current_user.api_key.destroy!
              audits_to_annotate << Audited.audit_class.where(auditable_id: original_api_key_id).last
            end
            current_user.build_api_key(key: SecureRandom.hex)
            current_user.save
            audits_to_annotate << current_user.api_key.audits.last
            annotate_audits audits_to_annotate
          end
        end
        current_user.api_key
      end

      desc 'View Current User API key' do
        detail 'View current_user api_key.'
        named 'view current_user api_key'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Current User Does not Exist']
        ]
      end
      get '/current_user/api_key', serializer: ApiKeySerializer do
        authenticate!
        current_user.api_key
      end

      desc 'Delete a Current User API key' do
        detail 'Delete a Current User API key'
        named 'delete current_user api_key'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Current User Does not Exist']
        ]
      end
      delete '/current_user/api_key', root: false do
        authenticate!
        Audited.audit_class.as_user(current_user) do
          current_user.api_key.destroy!
          annotate_audits [current_user.api_key.audits.last]
        end
        body false
      end
    end
  end
end
