module DDS
  module V1
    class TrashbinAPI < Grape::API
      helpers PaginationParams

      desc 'List Projects with Items in Trashbin' do
        detail 'List Projects with Items in Trashbin.'
        named 'list trashbin children'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'}
        ]
      end
      params do
        use :pagination
      end
      get '/trashbin/projects', adapter: :json, root: 'results' do
        authenticate!
        paginate(policy_scope(Project).joins(:containers).where(containers: {parent_id: nil, is_deleted:true, is_purged: false}).distinct)
      end

      desc 'View Trashbin Item details' do
        detail 'Show Details of a Trashbin Item.'
        named 'show trashbin item'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden'},
          {code: 404, message: 'Item Does not Exist'},
          {code: 404, message: 'Object kind not supported'}
        ]
      end
      params do
        requires :object_kind, type: String, desc: 'Object Kind'
        requires :object_id, type: String, desc: 'Object UUID'
      end
      get '/trashbin/:object_kind/:object_id', root: false do
        authenticate!
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        trashed_object = object_kind.find_by!(id: params[:object_id], is_deleted: true, is_purged: false)
        authorize trashed_object, :show?
        trashed_object
      end

      desc 'Restore a Trashbin Item' do
        detail 'Restores the item, and any children, to an undeleted status to the specified parent folder or project.'
        named 'restore trashbin item'
        failure [
          {code: 200, message: 'Success'},
          {code: 404, message: 'Parent object does not exist or is itself in the trashbin'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden'},
          {code: 404, message: 'Object or Parent kind not supported'},
          {code: 404, message: 'Object not found in trash bin'},
          {code: 404, message: 'Parent object does not exist or is itself in the trashbin'}
        ]
      end
      params do
        requires :object_kind, type: String, desc: 'Object Kind'
        requires :object_id, type: String, desc: 'Object UUID'
        optional :parent, desc: "Parent. Required unless restoring a FileVersion", type: Hash do
          optional :kind, type: String, desc: 'Parent Kind'
          optional :id, type: String, desc: 'Parent UUID'
        end
      end
      rescue_from TrashbinParentException do |e|
        message, suggestion = e.message.split('::')
        error_json = {
          "error" => "404",
          "code" => "not_provided",
          "reason" => message,
          "suggestion" => suggestion
        }
        error!(error_json, 404)
      end
      rescue_from IncompatibleParentException do |e|
        message, suggestion = e.message.split('::')
        error_json = {
          "error" => "404",
          "code" => "not_provided",
          "reason" => message,
          "suggestion" => suggestion
        }
        error!(error_json, 404)
      end
      rescue_from UnRestorableException do |e|
        error_json = {
          "error" => "404",
          "code" => "not_provided",
          "reason" => "#{e.message} Not Restorable",
          "suggestion" => "#{e.message} is not Restorable"
        }
        error!(error_json, 404)
      end
      put '/trashbin/:object_kind/:object_id/restore', root: false do
        authenticate!
        parent_params = declared(params, {include_missing: false}, [:parent])
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        purge_object = object_kind.find_by!(id: params[:object_id], is_deleted: true)
        authorize purge_object, :destroy?
        raise UnRestorableException.new(purge_object.kind) unless purge_object.class.include? Restorable
        if purge_object.is_purged?
          purge_object
        else
          target_parent = purge_object.deleted_from_parent || purge_object.project
          if params[:parent]
            parent_kind = KindnessFactory.by_kind(parent_params[:parent][:kind])
            target_parent = parent_kind.find(parent_params[:parent][:id])
          end

          target_parent.restore purge_object
          authorize purge_object, :restore?
          if purge_object.save
            purge_object
          else
            validation_error!(purge_object)
          end
        end
      end

      desc 'Purge Trashbin Item' do
        detail 'Purges the item and any children, and permenantly removes any stored files from the storage_provider. If a FileVersion is restored, the parent is optional, otherwise it is required.'
        named 'purge trashbin item'
        failure [
          {code: 204, message: 'Successfully Purged'},
          {code: 401, message: 'Unauthorized'},
          {code: 403, message: 'Forbidden'},
          {code: 404, message: 'Item Does not Exist'},
          {code: 404, message: 'Object kind not supported'}
        ]
      end
      params do
        requires :object_kind, type: String, desc: 'Object Kind'
        requires :object_id, type: String, desc: 'Object UUID'
      end
      rescue_from UnPurgableException do |e|
        error_json = {
          "error" => "404",
          "code" => "not_provided",
          "reason" => "#{e.message} Not Purgable",
          "suggestion" => "#{e.message} is not Purgable"
        }
        error!(error_json, 404)
      end
      put '/trashbin/:object_kind/:object_id/purge', root: false do
        authenticate!
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        purge_object = object_kind.find_by!(id: params[:object_id], is_deleted: true)
        raise UnPurgableException.new(purge_object.kind) unless purge_object.class.include? Purgable
        unless purge_object.is_purged?
          purge_object.purge
          authorize purge_object, :destroy?
          purge_object.save
        end
        body false
      end

      desc 'List folder children in trashbin' do
        detail 'Returns the trashed children of the folder.'
        named 'list folder children in the trashbin'
        failure [
          {code: 200, message: "Valid API Token in 'Authorization' Header"},
          {code: 401, message: "Missing, Expired, or Invalid API Token in 'Authorization' Header"},
          {code: 404, message: 'Folder does not exist or is purged'}
        ]
      end
      params do
        optional :name_contains, type: String, desc: 'list children whose name contains this string'
        optional :recurse, type: Boolean, desc: 'If true, searches recursively into subfolders'
        use :pagination
      end
      get '/trashbin/folders/:id/children', adapter: :json, root: 'results' do
        authenticate!
        folder = Folder.find_by!(id: params[:id], is_purged: false)
        authorize folder, :index?
        name_contains = params[:name_contains]
        descendants = params[:recurse] ? policy_scope(folder.descendants) : policy_scope(folder.children)
        descendants = descendants.unscope(:order).where(is_deleted: true, is_purged: false)
        if name_contains
          if name_contains.empty?
            descendants = descendants.none
          else
            descendants = descendants.where(Container.arel_table[:name].matches("%#{name_contains}%"))
          end
        end
        paginate(descendants.includes(:parent, :project, :audits).order('updated_at ASC'))
      end

      desc 'List project children in the trashbin' do
        detail 'Returns the trashed children of the project.'
        named 'list project children in the trashbin'
        failure [
          {code: 200, message: "Valid API Token in 'Authorization' Header"},
          {code: 401, message: "Missing, Expired, or Invalid API Token in 'Authorization' Header"},
          {code: 404, message: 'Project does not exist or has been deleted'}
        ]
      end
      params do
        optional :name_contains, type: String, desc: 'list children whose name contains this string'
        optional :recurse, type: Boolean, desc: 'If true, searches recursively into subfolders'
        use :pagination
      end
      get '/trashbin/projects/:id/children', adapter: :json, root: 'results' do
        authenticate!
        project = hide_logically_deleted Project.find(params[:id])
        authorize DataFile.new(project: project), :index?
        name_contains = params[:name_contains]
        descendants = params[:recurse] ? project.containers : project.children
        descendants = descendants.unscope(:order).where(is_deleted: true, is_purged: false)
        if name_contains
          if name_contains.empty?
            descendants = descendants.none
          else
            descendants = descendants.where(Container.arel_table[:name].matches("%#{name_contains}%"))
          end
        end
        paginate(policy_scope(descendants.includes(:parent, :project, :audits).order('updated_at ASC')))
      end
    end
  end
end
