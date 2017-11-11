module DDS
  module V1
    class TrashbinAPI < Grape::API
      helpers PaginationParams

      desc 'View Trashbin Item details' do
        detail 'Show Details of a Trashbin Item.'
        named 'show trashbin item'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Item Does not Exist'],
          [404, 'Object kind not supported']
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
          [200, 'Success'],
          [404, 'Parent object does not exist or is itself in the trashbin'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Object or Parent kind not supported'],
          [404, 'Object not found in trash bin'],
          [404, 'Parent object does not exist or is itself in the trashbin']
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
      put '/trashbin/:object_kind/:object_id/restore', root: false do
        authenticate!
        parent_params = declared(params, {include_missing: false}, [:parent])
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        purge_object = object_kind.find_by!(id: params[:object_id], is_deleted: true)
        unless purge_object.class.include? Restorable
          error_json = {
            "error" => "404",
            "code" => "not_provided",
            "reason" => "#{purge_object.class.to_s} Not Found",
            "suggestion" => "#{purge_object.kind} is not Restorable"
          }
          error!(error_json, 404)
        end
        unless purge_object.is_purged?
          purge_object.is_deleted = false
          if purge_object.is_a?(FileVersion)
            if purge_object.data_file.is_deleted?
              error_json = {
                "error" => "404",
                "code" => "not_provided",
                "reason" => "DataFile Not Found",
                "suggestion" => "Restore #{purge_object.data_file.kind} #{purge_object.data_file_id}"
              }
              error!(error_json, 404)
            end
          else
            parent_kind = KindnessFactory.by_kind(parent_params[:parent][:kind])
            purge_object.parent = hide_logically_deleted parent_kind.find(parent_params[:parent][:id])
          end
          authorize purge_object, :restore?
          purge_object.save
        end
        purge_object
      end

      desc 'Purge Trashbin Item' do
        detail 'Purges the item and any children, and permenantly removes any stored files from the storage_provider. If a FileVersion is restored, the parent is optional, otherwise it is required.'
        named 'purge trashbin item'
        failure [
          [200, 'Successfully Purged'],
          [401, 'Unauthorized'],
          [403, 'Forbidden'],
          [404, 'Item Does not Exist'],
          [404, 'Object kind not supported']
        ]
      end
      params do
        requires :object_kind, type: String, desc: 'Object Kind'
        requires :object_id, type: String, desc: 'Object UUID'
      end
      put '/trashbin/:object_kind/:object_id/purge', root: false do
        authenticate!
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        purge_object = object_kind.find_by!(id: params[:object_id], is_deleted: true)
        unless purge_object.class.include? Restorable
          error_json = {
            "error" => "404",
            "code" => "not_provided",
            "reason" => "#{purge_object.class.to_s} Not Found",
            "suggestion" => "#{purge_object.kind} is not Purgable"
          }
          error!(error_json, 404)
        end
        if purge_object.is_a?(FileVersion)
          error_json = {
            "error" => "404",
            "code" => "not_provided",
            "reason" => "#{purge_object.class.to_s} Not Found",
            "suggestion" => "#{purge_object.kind} is not Purgable"
          }
          error!(error_json, 404)
        end
        authorize purge_object, :destroy?
        unless purge_object.is_purged?
          purge_object.update(is_deleted: true, is_purged: true)
        end
        body false
      end

      desc 'List folder children in trashbin' do
        detail 'Returns the trashed children of the folder.'
        named 'list folder children in the trashbin'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Folder does not exist or is purged']
        ]
      end
      params do
        optional :name_contains, type: String, desc: 'list children whose name contains this string'
        optional :recurse, type: Boolean, desc: 'If true, searches recursively into subfolders'
        use :pagination
      end
      get '/trashbin/folders/:id/children', root: 'results' do
        authenticate!
        folder = Folder.find_by!(id: params[:id], is_purged: false)
        authorize folder, :index?
        name_contains = params[:name_contains]
        descendants = params[:recurse] ? policy_scope(folder.descendants) : policy_scope(folder.children)
        descendants = descendants.where(is_deleted: true, is_purged: false)
        if name_contains
          if name_contains.empty?
            descendants = descendants.none
          else
            descendants = descendants.where(Container.arel_table[:name].matches("%#{name_contains}%"))
          end
        end
        paginate(descendants.includes(:parent, :project, :audits))
      end

      desc 'List project children in the trashbin' do
        detail 'Returns the trashed children of the project.'
        named 'list project children in the trashbin'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Project does not exist or has been deleted']
        ]
      end
      params do
        optional :name_contains, type: String, desc: 'list children whose name contains this string'
        optional :recurse, type: Boolean, desc: 'If true, searches recursively into subfolders'
        use :pagination
      end
      get '/trashbin/projects/:id/children', root: 'results' do
        authenticate!
        project = hide_logically_deleted Project.find(params[:id])
        authorize DataFile.new(project: project), :index?
        name_contains = params[:name_contains]
        descendants = params[:recurse] ? project.containers : project.children
        descendants = descendants.where(is_deleted: true, is_purged: false)
        if name_contains
          if name_contains.empty?
            descendants = descendants.none
          else
            descendants = descendants.where(Container.arel_table[:name].matches("%#{name_contains}%"))
          end
        end
        paginate(policy_scope(descendants.includes(:parent, :project, :audits)))
      end
    end
  end
end
