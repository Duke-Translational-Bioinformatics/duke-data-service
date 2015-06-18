module DDS
  module V1
    class AppAPI < Grape::API
      desc 'app status' do
        detail 'this returns a health status'
        named 'app_storage'
      end
      get '/app/status', root: false do
        begin
          {status: 'ok'}
        rescue
          error!('problem encountered',503)
        end
      end
    end
  end
end
