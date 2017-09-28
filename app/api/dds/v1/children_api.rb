module DDS
  module V1
    class ChildrenAPI < Grape::API
      helpers PaginationParams

      desc 'List folder children' do
        detail 'Returns the immediate children of the folder.'
        named 'list folder children'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Folder does not exist']
        ]
      end
      params do
        optional :name_contains, type: String, desc: 'list children whose name contains this string'
        use :pagination
      end
      get '/folders/:id/children', root: 'results' do
        authenticate!
        folder = hide_logically_deleted Folder.find(params[:id])
        authorize folder, :index?
        name_contains = params[:name_contains]
        if name_contains.nil?
          descendants = policy_scope(folder.children)
        else
          descendants = policy_scope(folder.descendants).where(Container.arel_table[:name].matches("%#{name_contains}%"))
        end
        paginate(descendants.includes(:parent, :project, :audits).where(is_deleted: false))
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
        use :pagination
      end
      get '/projects/:id/children', root: 'results' do
        authenticate!
        name_contains = params[:name_contains]
        project = hide_logically_deleted Project.find(params[:id])
        authorize DataFile.new(project: project), :index?
        if name_contains.nil?
          descendants = project.children
        else
          descendants = project.containers.where(Container.arel_table[:name].matches("%#{name_contains}%"))
        end
        paginate(policy_scope(descendants.includes(:parent, :project, :audits)).where(is_deleted: false))
      end
    end
  end
end
