module DDS
  module V1
    class ChildrenAPI < Grape::API
      desc 'List folder children' do
        detail 'Returns the immediate children of the folder.'
        named 'list folder children'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Folder does not exist']
        ]
      end
      get '/folders/:id/children', root: false do
        authenticate!
        folder = hide_logically_deleted Folder.find(params[:id])
        authorize folder, :show?
        #folder
      end
    end
  end
end
