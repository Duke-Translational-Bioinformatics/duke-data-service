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
        begin
          auth_roles = AuthRole.all.count
          if auth_roles < 1
            logger.error("database not seeded")
            raise 'database not seeded'
          end
          {status: 'ok', environment: "#{Rails.env}"}
        rescue Exception => e
          error!({status: 'error', message: e.message},503)
        end
      end
    end
  end
end
