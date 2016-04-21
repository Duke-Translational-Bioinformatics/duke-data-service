module DDS
  module V1
    class AppAPI < Grape::API
      desc 'app status' do
        detail 'this returns a health status'
        named 'app_storage'
        failure [
          [200,'Database functional, and seeded correctly'],
          [503, 'database not seeded, or not functional']
        ]
      end
      get '/app/status', root: false do
        status = {status: 'ok', environment: "#{Rails.env}", rdbms: 'ok', authentication_service: 'not tested', storage_provider: 'not tested', graphdb: 'not tested'}
        begin
          #rdbms must be connected and seeded
          auth_roles = AuthRole.all.count
          if auth_roles < 1
            status[:status] = 'error'
            status[:rdbms] = 'is not seeded'
          end

          # authentication_service must be configured
          if ENV["AUTH_SERVICE_ID"] &&
             ENV["AUTH_SERVICE_BASE_URI"] &&
             ENV["AUTH_SERVICE_NAME"]
            as_count = AuthenticationService.count
            if as_count == 0
              status[:status] = 'error'
              status[:authentication_service] = 'has not been created'
            else
              status[:authentication_service] = 'ok'
            end
          else
           status[:status] = 'error'
           status["authentication_service"] = 'environment is not set'
          end

          # storage_provider must be configured
          if ENV["SWIFT_ACCT"] &&
             ENV["SWIFT_URL_ROOT"] &&
             ENV["SWIFT_USER"] &&
             ENV["SWIFT_PASS"] &&
             ENV["SWIFT_PRIMARY_KEY"] &&
             ENV["SWIFT_SECONDARY_KEY"]
            #storage_provider must be created
            sp = StorageProvider.first
            if sp
              #storage_provider must be accessible over http without network or CORS issues
              sp_acct = sp.get_account_info
              # storage_provider must register_keys
              if sp_acct.has_key?("x-account-meta-temp-url-key") &&
                     sp_acct.has_key?("x-account-meta-temp-url-key-2") &&
                     sp_acct["x-account-meta-temp-url-key"] &&
                     sp_acct["x-account-meta-temp-url-key-2"]
                status[:storage_provider] = 'ok'
              else
                status[:status] = 'error'
                status[:storage_provider] = 'has not registered its keys'
              end
            else
              status[:status] = 'error'
              status[:storage_provider] = 'has not been created'
            end
          else
            status[:status] = 'error'
            status[:storage_provider] = 'environment is not set'
          end

          #graphdb must be configured
          if ENV["GRAPHSTORY_URL"]
            #graphdb must be accessible with configured authentication
            count = Neo4j::Session.query('MATCH (n) RETURN COUNT(n)').first["COUNT(n)"]
            if count >= 0
              status[:graphdb] = 'ok'
            end
          else
            status[:status] = 'error'
            status[:graphdb] = 'environment is not set'
          end

          status
        rescue StorageProviderException => e
          logger.error("StorageProvider error #{e.message}")
          status[:status] = 'error'
          status[:storage_provider] = "not connected"
          error!(status,503)
        rescue Faraday::ConnectionFailed => e
          logger.error("GraphDB Connection error #{e.message}")
          status[:status] = 'error'
          status[:graphdb] = 'is not connected'
          error!(status,503)
        rescue Exception => e
          logger.error("GOT Exception "+e.inspect)
          status[:status] = 'error'
          error!(status,503)
        end
      end
    end
  end
end
