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
    end
  end
end
