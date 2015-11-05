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
      get '/folders/:id/children', root: 'results' do
        authenticate!
        folder = hide_logically_deleted Folder.find(params[:id])
        authorize folder, :show?
        folder.children.where(is_deleted: false)
      end

      desc 'List project children' do
        detail 'Returns the immediate children of the project.'
        named 'list project children'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Project does not exist']
        ]
      end
      params do
        optional :name_contains, type: String, desc: 'list children whose name contains this string'
      end
      get '/projects/:id/children', root: 'results' do
        authenticate!
        name_contains = params[:name_contains]
        project = hide_logically_deleted Project.find(params[:id])
        authorize project, :show?
        if name_contains.nil? # return only the direct children
          decendants = project.children
        else # return all decendants that have the name_contains in there name field
          decendants = project.containers.where("name like ?", "%#{name_contains}%")
        end
        decendants.where(is_deleted: false)
      end
    end
  end
end
