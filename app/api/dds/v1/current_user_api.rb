module DDS
  module V1
    class CurrentUserAPI < Grape::API
      namespace :current_user do
        desc 'current_user' do
          detail 'allows a user to get their User object with a valid api_token'
          named 'current_user'
          failure [
            [200, "Success"],
            [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"]
          ]
        end
        get '/', root: false do
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
        get '/usage', serializer: UserUsageSerializer do
          authenticate!
          current_user
        end
      end
    end
  end
end
