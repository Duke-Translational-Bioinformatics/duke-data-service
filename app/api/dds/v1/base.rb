require 'grape-swagger'

module DDS
  module V1
    class Base < Grape::API
      include Grape::Kaminari
      version 'v1', using: :path
      content_type :json, 'application/json'
      format :json
      default_format :json
      formatter :json, Grape::Formatter::ActiveModelSerializers
      prefix :api
      paginate offset: false

      helpers Pundit
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

        def annotate_audits(audits = [], additional_annotation = nil)
          request_annotation = {
            request_uuid: SecureRandom.hex,
            remote_address: request.ip
          }
          comment_annotation = {
            endpoint: request.env["REQUEST_URI"],
            action: request.env["REQUEST_METHOD"]
          }
          audit_annotation = additional_annotation ?
            additional_annotation.merge(request_annotation) :
            request_annotation

          audits.each do |audit|
            audit_update = audit_annotation
            audit_update[:comment] = audit.comment ?
              audit.comment.merge(comment_annotation) :
              comment_annotation
            audit.update(audit_update)
          end
        end

        def hide_logically_deleted(object)
          if object.is_deleted
            raise ActiveRecord::RecordNotFound.new("find #{object.class.name} with #{object.id} not found")
          end
          object
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

      rescue_from Pundit::NotAuthorizedError do |e|
        error_json = {
          "error" => "403",
          "reason" => "Unauthorized",
          "suggestion" => "request permission to access this resource"
        }
        error!(error_json, 403)
      end

      rescue_from StorageProviderException do |e|
        error_json = {
          "error" => "500",
          "reason" => 'The storage provider is unavailable',
          "suggestion" => 'try again in a few minutes, or contact the systems administrators'
        }
        error!(error_json, 500)
      end

      mount DDS::V1::UserAPI
      mount DDS::V1::SystemPermissionsAPI
      mount DDS::V1::AppAPI
      mount DDS::V1::CurrentUserAPI
      mount DDS::V1::ProjectsAPI
      mount DDS::V1::ProjectAffiliatesAPI
      mount DDS::V1::AuthRolesAPI
      mount DDS::V1::ProjectPermissionsAPI
      mount DDS::V1::FoldersAPI
      mount DDS::V1::UploadsAPI
      mount DDS::V1::FilesAPI
      mount DDS::V1::ProjectRolesAPI
      mount DDS::V1::StorageProvidersAPI
      # mount DDS::V1::ParentChildrenAPI
      add_swagger_documentation(
        api_version: 'v1',
        hide_format: true
      )
    end
  end
end
