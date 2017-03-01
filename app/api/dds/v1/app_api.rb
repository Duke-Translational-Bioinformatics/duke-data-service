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
        status = {status: 'ok', environment: "#{Rails.env}", rdbms: 'ok', authentication_service: 'not tested', storage_provider: 'not tested', graphdb: 'not tested', queue: 'not tested'}
        begin
          #rdbms must be connected and seeded
          auth_roles = AuthRole.all.count
          if auth_roles < 1
            status[:status] = 'error'
            status[:rdbms] = 'is not seeded'
          end

          # authentication_service must be configured
          as_count = AuthenticationService.count
          if as_count == 0
            status[:status] = 'error'
            status[:authentication_service] = 'has not been created'
          else
            status[:authentication_service] = 'ok'
          end

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

          #graphdb must be configured
          if ENV["GRAPHSTORY_URL"]
            #graphdb must be accessible with configured authentication or this will throw a Faraday::ConnectionFailed exception
            count = Neo4j::Session.query('MATCH (n) RETURN COUNT(n)').first["COUNT(n)"]
            status[:graphdb] = 'ok'
          else
            status[:status] = 'error'
            status[:graphdb] = 'environment is not set'
          end

          if ENV['CLOUDAMQP_URL']
            missing_exchanges = [
              ApplicationJob.opts[:exchange],
              ApplicationJob.distributor_exchange_name
            ].reject do |expected_exchange|
              ApplicationJob.conn.exchange_exists? expected_exchange
            end

            if missing_exchanges.empty?
              queue_names = (ApplicationJob.descendants.collect {|d| d.queue_name }).uniq
              missing_queues = ['message_log'].concat(queue_names).reject do |expected_queue|
                ApplicationJob.conn.queue_exists? expected_queue
              end

              if missing_queues.empty?
                status[:queue] = 'ok'
              else
                status[:queue] = "is missing expected queues #{missing_queues.join(' ')}"
              end
            else
              status[:queue] = "is missing expected exchanges #{missing_exchanges.join(' ')}"
            end
          else
            status[:queue] = 'environment is not set'
          end

          if status[:status] == 'ok'
            status
          else
            error!(status,503)
          end
        rescue StorageProviderException => e
          logger.error("StorageProvider error #{e.message}")
          status[:status] = 'error'
          status[:storage_provider] = "is not connected"
          error!(status,503)
        rescue Faraday::ConnectionFailed => e
          logger.error("GraphDB Connection error #{e.message}")
          status[:status] = 'error'
          status[:graphdb] = 'is not connected'
          error!(status,503)
        rescue Bunny::TCPConnectionFailedForAllHosts => e
          logger.error("RabbitMQ Connection error #{e.message}")
          status[:status] = 'error'
          status[:queue] = 'is not connected'
          error!(status, 503)
        rescue Exception => e
          logger.error("GOT UNKOWNN Exception "+e.inspect)
          status[:status] = 'error'
          error!(status,503)
        end
      end
    end
  end
end
