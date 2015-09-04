require 'grape-swagger'

module DDS
  module V1
    class Base < Grape::API
      version 'v1', using: :path
      content_type :json, 'application/json'
      format :json
      default_format :json
      formatter :json, Grape::Formatter::ActiveModelSerializers
      prefix :api

      helpers do
        def logger
          Rails.logger
        end

        def authenticate!
          unless current_user
            @auth_error[:error] = 401
            error!(@auth_error, 401)
          end
        end

        def current_user
          if @current_user
            return @current_user
          end
          api_token = headers["Authorization"]
          if api_token
            begin
              decoded_token = JWT.decode(api_token, Rails.application.secrets.secret_key_base)[0]
              @current_user = find_user_with_token(decoded_token)
            rescue JWT::VerificationError
              @current_user = nil
              @auth_error = {
                reason: 'invalid api_token',
                suggestion: 'token not properly signed'
              }
            rescue JWT::ExpiredSignature
              @current_user = nil
              @auth_error = {
                reason: 'expired api_token',
                suggestion: 'you need to login with your authenticaton service'
              }
            end
          else
            @auth_error = {
              error: 401,
              reason: 'no api_token',
              suggestion: 'you might need to login through an authenticaton service'
            }
            error!(@auth_error, 401)
          end
          @current_user
        end

        def find_user_with_token(decoded_token)
          User.find(decoded_token['id'])
        end

        def validation_error!(object)
          error_payload = {
            error: '400',
            reason: 'validation failed',
            suggestion: 'Fix the following invalid fields and resubmit',
            errors: []
          }
          object.errors.messages.each do |field, errors|
            errors.each do |message|
              error_payload[:errors] << {
                field: field,
                message: message
              }
            end
          end
          error!(error_payload, 400)
        end
      end

      rescue_from ActiveRecord::RecordNotFound do |e|
        missing_object = ''
        m = e.message.match(/find\s(\w+)\swith.*/)
        if m
          missing_object = m[1]
        end
        error_json = {
          "error" => "404",
          "reason" => "#{missing_object} Not Found",
          "suggestion" => "you may have mistyped the #{missing_object} id"
        }
        error!(error_json, 404)
      end

      mount DDS::V1::UserAPI
      mount DDS::V1::SystemPermissionsAPI
      mount DDS::V1::AppAPI
      mount DDS::V1::CurrentUserAPI
      mount DDS::V1::ProjectsAPI
      mount DDS::V1::ProjectAffiliatesAPI
      mount DDS::V1::AuthRolesAPI
      mount DDS::V1::ProjectPermissionsAPI
      mount DDS::V1::FolderAPI
      mount DDS::V1::UploadsAPI
      mount DDS::V1::FileAPI
      add_swagger_documentation(
        api_version: 'v1',
        hide_format: true
      )
    end
  end
end
