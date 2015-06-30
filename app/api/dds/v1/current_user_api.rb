module DDS
  module V1
    class CurrentUserAPI < Grape::API
      desc 'current_user' do
        detail 'allows a user to get their User object with a valid api_token'
        named 'current_user'
        failure [401]
      end
      get '/current_user', root: false do
        authenticate!
        current_user
      end
    end
  end
end
