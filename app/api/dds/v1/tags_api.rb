module DDS
  module V1
    class TagsAPI < Grape::API
      desc 'Create object tag' do
        detail 'Creates an object tag.'
        named 'create object tag'
        failure [
          [200, 'this will never happen'],
          [201, 'Successfully Created'],
          [400, 'Tag requires a lable'],
          [401, 'Unauthorized'],
          [404, 'Aaaggggh']
        ]
      end
      params do
        requires :object, desc: "DataFile ID", type: Hash do
          requires :kind, type: String, desc: "DataFile kind"
          requires :id, type: String, desc: "DataFile UUID"
        end
        requires :label
      end
      post '/tags', root: false do
        authenticate!
        data_file = DataFile.find(params[:object][:id])
        tag_params = declared(params, include_missing: false)
        tag = Tag.new(
          label: tag_params[:label],
          taggable: data_file
          )
        authorize tag, :create?
        Audited.audit_class.as_user(current_user) do
          if tag.save
            annotate_audits [tag.audits.last]
            tag
          else
            validation_error!(tag)
          end
        end
      end

      desc 'List tag objects' do
        detail 'Lists tag objects for which the current user has the "view_project" permission.'
        named 'list tag objects'
        failure [
          [200, 'Success'],
          [401, 'Unauthorized']
        ]
      end
      get '/tags/:object_kind/:object_id', root: 'results' do
        authenticate!
        data_file = DataFile.find(params[:object_id])
        authorize Tag.new(taggable: data_file), :index?
        policy_scope(Tag).where(taggable: data_file)
      end

      desc 'View tag' do
        detail 'view tag'
        named 'view tag'
        failure [
          [200, "Valid API Token in 'Authorization' Header"],
          [401, "Missing, Expired, or Invalid API Token in 'Authorization' Header"],
          [404, 'Tag does not exist']
        ]
      end
      params do
      end
      get '/tags/:id', root: false do
        authenticate!
        tag = Tag.find(params[:id])
        authorize tag, :show?
        tag
      end
    end
  end
end
