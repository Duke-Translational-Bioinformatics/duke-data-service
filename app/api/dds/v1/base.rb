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
      end

      mount DDS::V1::UserAPI
      mount DDS::V1::SystemPermissionsAPI
      mount DDS::V1::AppAPI
    end
  end
end
