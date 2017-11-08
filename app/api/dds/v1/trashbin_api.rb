module DDS
  module V1
    class TrashbinAPI < Grape::API
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
    end
  end
end
