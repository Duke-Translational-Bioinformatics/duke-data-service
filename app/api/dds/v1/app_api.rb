module DDS
  module V1
    class AppAPI < Grape::API
      desc 'app status' do
        detail 'this returns a health status'
        named 'app_storage'
        failure [
          {code: 200, message: 'Database functional, and seeded correctly'},
          {code: 503, message: 'database not seeded, or not functional'}
        ]
      end
      get '/app/status', root: false do
        status = {status: 'ok', environment: "#{Rails.env}"}
        begin
          #rdbms must be connected and seeded
          auth_roles = AuthRole.all.count
          if auth_roles < 1
            status[:status] = 'error'
            logger.error('rdbms is not seeded')
          end

          # authentication_service must be configured
          as_count = AuthenticationService.count
          if as_count == 0
            status[:status] = 'error'
            logger.error 'authentication_service has not been created'
          end

          #default storage_provider must be created
          sp = StorageProvider.default
          if sp
            # this raises a StorageProviderException or returns true
            sp.is_ready?
          else
            status[:status] = 'error'
            logger.error 'storage_provider has not been created'
          end

          #graphdb must be configured
          if ENV["GRAPHENEDB_URL"]
            #graphdb must be accessible with configured authentication or this will throw a Faraday::ConnectionFailed exception
            Neo4j::ActiveBase.current_session.query('MATCH (n) RETURN COUNT(n)').first["COUNT(n)"]
          else
            status[:status] = 'error'
            logger.error 'graphdb environment is not set'
          end
          bunny_connection = Sneakers::CONFIG[:connection].start
          if ENV['CLOUDAMQP_URL']
            [
              Sneakers::CONFIG[:exchange],
              ApplicationJob.distributor_exchange_name
            ].each do |expected_exchange|
              unless bunny_connection.exchange_exists? expected_exchange
                status[:status] = 'error'
                logger.error "queue is missing expected exchange #{expected_exchange}"
              end
            end

            application_job_workers = ApplicationJob.descendants.collect &:queue_name

            [
              MessageLogWorker.new.queue.name
            ].concat(application_job_workers)
            .each do |expected_queue|
              unless bunny_connection.queue_exists? expected_queue
                status[:status] = 'error'
                logger.error "queue is missing expected queue #{expected_queue}"
              end
            end
          else
            status[:status] = 'error'
            logger.error 'queue environment is not set'
          end

          if status[:status] == 'ok'
            status
          else
            error!(status,503)
          end
        rescue StorageProviderException => e
          logger.error("StorageProvider error #{e.message}")
          status[:status] = 'error'
          error!(status,503)
        rescue Bunny::TCPConnectionFailedForAllHosts => e
          logger.error("RabbitMQ Connection error #{e.message}")
          status[:status] = 'error'
          logger.error 'queue is not connected'
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
