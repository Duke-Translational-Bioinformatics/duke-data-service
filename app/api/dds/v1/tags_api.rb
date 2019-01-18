module DDS
  module V1
    class TagsAPI < Grape::API
      desc 'Create object tag' do
        detail 'Creates an object tag.'
        named 'create object tag'
        failure [
          {code: 200, message: 'This will never happen'},
          {code: 201, message: 'Successfully Created'},
          {code: 400, message: 'Tag requires a label'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Tag does not exist'}
        ]
      end
      params do
        requires :label
      end
      post '/tags/:object_kind/:object_id', root: false do
        authenticate!
        tag_params = declared(params, include_missing: false)
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        taggable_object = object_kind.find(params[:object_id])
        tag = Tag.new(
          label: tag_params[:label],
          taggable: taggable_object
        )
        authorize tag, :create?
        if tag.save
          tag
        else
          validation_error!(tag)
        end
      end

      desc 'List tag objects' do
        detail 'Lists tag objects for which the current user has the "view_project" permission.'
        named 'list tag objects'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'}
        ]
      end
      get '/tags/:object_kind/:object_id', adapter: :json, root: 'results' do
        authenticate!
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        taggable_object = object_kind.find(params[:object_id])
        authorize Tag.new(taggable: taggable_object), :index?
        policy_scope(Tag).where(taggable: taggable_object)
      end

      desc 'Append a list of object tags' do
        detail 'Append a list of tags to an object.'
        named 'append object tags'
        failure [
          {code: 200, message: 'This will never happen'},
          {code: 201, message: 'Successfully Created'},
          {code: 400, message: 'Tag requires a label'},
          {code: 401, message: 'Unauthorized'},
          {code: 404, message: 'Tag does not exist'}
        ]
      end
      params do
        requires :tags, type: Array do
          requires :label, type: String, desc: "The textual tag content"
        end
      end
      post '/tags/:object_kind/:object_id/append', adapter: :json, root: 'results' do
        authenticate!
        append_params = declared(params, include_missing: false)
        object_kind = KindnessFactory.by_kind(params[:object_kind])
        taggable_object = object_kind.find(params[:object_id])
        new_tags = []
        append_params[:tags].each do |tag_params|
          tag = Tag.new(
            label: tag_params[:label],
            taggable: taggable_object
          )
          authorize tag, :create?
          if taggable_object.tags << tag
            new_tags << tag
          end
        end
        new_tags
      end

      desc 'List tag labels' do
        detail 'Get a list of the distinct tag label values visible to the current user.'
        named 'list tag labels'
        failure [
          {code: 200, message: 'Success'},
          {code: 401, message: 'Unauthorized'}
        ]
      end
      params do
        optional :object_kind, type: String, desc: "Restricts search scope to tags for this kind of object"
        optional :label_contains, type: String, desc: "Searches for tags that contain this text fragment"
      end
      get '/tags/labels', adapter: :json, root: 'results' do
        authenticate!
        tag_params = declared(params, include_missing: false)
        scoped_tags = policy_scope(Tag)
        if tag_params[:label_contains]
          scoped_tags = scoped_tags.where("label LIKE ?", "%#{tag_params[:label_contains]}%")
        end
        if tag_params[:object_kind]
          object_kind = KindnessFactory.by_kind(tag_params[:object_kind])
          scoped_tags = scoped_tags.where(taggable_type: object_kind.base_class.name)
        end
        scoped_tags.tag_labels
      end

      desc 'View tag' do
        detail 'view tag'
        named 'view tag'
        failure [
          {code: 200, message: 'Valid API Token in \'Authorization\' Header'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'Tag does not exist'}
        ]
      end
      get '/tags/:id', root: false do
        authenticate!
        tag = Tag.find(params[:id])
        authorize tag, :show?
        tag
      end

      desc 'Delete a tag' do
        detail 'Deletes the tag'
        named 'delete tag'
        failure [
          {code: 204, message: 'Successfully Deleted'},
          {code: 401, message: 'Missing, Expired, or Invalid API Token in \'Authorization\' Header'},
          {code: 404, message: 'Tag does not exist'}
        ]
      end
      delete '/tags/:id', root: false do
        authenticate!
        tag = Tag.find(params[:id])
        authorize tag, :destroy?
        tag.destroy
        body false
      end
    end
  end
end
